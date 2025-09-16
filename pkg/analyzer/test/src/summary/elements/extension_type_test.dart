// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
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
  test_allSupertypes() async {
    var library = await buildLibrary(r'''
extension type A(int? it) {}
extension type B(int it) implements A, num {}
''');

    configuration
      ..withConstructors = false
      ..withAllSupertypes = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:22) (firstTokenOffset:16) (offset:22)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 it (nameOffset:50) (firstTokenOffset:45) (offset:50)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      interfaces
        A
        num
      allSupertypes
        A
        Comparable<num>
        Object
        num
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

  test_constructor_const() async {
    var library = await buildLibrary(r'''
extension type const A(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:27) (firstTokenOffset:22) (offset:27)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:22) (offset:21)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 21
              formalParameters
                #F4 this.it (nameOffset:27) (firstTokenOffset:22) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        const isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:27) (firstTokenOffset:16) (offset:27)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 named (nameOffset:17) (firstTokenOffset:16) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::named
              codeOffset: 16
              codeLength: 14
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F4 this.it (nameOffset:27) (firstTokenOffset:16) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::named
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 named (nameOffset:31) (firstTokenOffset:29) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 29
              periodOffset: 30
              formalParameters
                #F6 this.it (nameOffset:42) (firstTokenOffset:37) (offset:42)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: num
        isExtensionTypeMember named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: num
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 named (nameOffset:31) (firstTokenOffset:29) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 29
              periodOffset: 30
              formalParameters
                #F6 this.it (nameOffset:46) (firstTokenOffset:37) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: num
        isExtensionTypeMember named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final it
              firstFragment: #F6
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 const named (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 35
              periodOffset: 36
              formalParameters
                #F6 a (nameOffset:47) (firstTokenOffset:43) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::a
          getters
            #F7 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: num
        const isExtensionTypeMember named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F6
              type: int
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: it @52
                element: <testLibrary>::@extensionType::A::@field::it
                staticType: null
              equals: = @55
              expression: SimpleIdentifier
                token: a @57
                element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::a
                staticType: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 16
              codeLength: 8
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:24) (firstTokenOffset:0) (offset:24)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:30) (firstTokenOffset:25) (offset:30)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:25) (offset:24)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 24
              formalParameters
                #F4 this.it (nameOffset:30) (firstTokenOffset:25) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      documentationComment: /// Docs
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 hasInitializer foo (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@extensionType::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @52
                  staticType: int
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static const hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 hasInitializer foo (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@extensionType::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @48
                  staticType: int
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static const hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 hasInitializer foo (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: <testLibrary>::@extensionType::A::@field::foo
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        final hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      extensionTypes
        #F1 extension type A (nameOffset:32) (firstTokenOffset:17) (offset:32)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:43) (firstTokenOffset:33) (offset:43)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:33) (offset:32)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 32
              formalParameters
                #F4 this.it (nameOffset:43) (firstTokenOffset:33) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F5 foo (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
        #F3 class C (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::C
      extensionTypes
        #F4 extension type X (nameOffset:64) (firstTokenOffset:49) (offset:64)
          element: <testLibrary>::@extensionType::X
          fields
            #F5 it (nameOffset:68) (firstTokenOffset:65) (offset:68)
              element: <testLibrary>::@extensionType::X::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
              element: <testLibrary>::@extensionType::X::@getter::it
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      interfaces
        A
        B
  extensionTypes
    extension type X
      reference: <testLibrary>::@extensionType::X
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::X::@field::it
      primaryConstructor: <testLibrary>::@extensionType::X::@constructor::new
      typeErasure: C
      interfaces
        A
        B
      fields
        final it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F5
          type: C
          getter: <testLibrary>::@extensionType::X::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::X::@getter::it
          firstFragment: #F6
          returnType: C
          variable: <testLibrary>::@extensionType::X::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:56) (firstTokenOffset:41) (offset:56)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 it (nameOffset:62) (firstTokenOffset:57) (offset:62)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    hasImplementsSelfReference extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        Object
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    hasImplementsSelfReference extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      interfaces
        Object
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

  test_interfaces_cycle_self() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    hasImplementsSelfReference extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        Object
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:43) (firstTokenOffset:28) (offset:43)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 it (nameOffset:49) (firstTokenOffset:44) (offset:49)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      interfaces
        A
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

  test_interfaces_futureOr() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements num, FutureOr<int> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        num
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type X (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::X
          fields
            #F2 it (nameOffset:22) (firstTokenOffset:16) (offset:22)
              element: <testLibrary>::@extensionType::X::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@extensionType::X::@getter::it
  extensionTypes
    extension type X
      reference: <testLibrary>::@extensionType::X
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::X::@field::it
      primaryConstructor: <testLibrary>::@extensionType::X::@constructor::new
      typeErasure: int?
      fields
        final it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::X::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::X::@getter::it
          firstFragment: #F3
          returnType: int?
          variable: <testLibrary>::@extensionType::X::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          fields
            #F3 it (nameOffset:22) (firstTokenOffset:19) (offset:22)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: T
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type X (nameOffset:33) (firstTokenOffset:18) (offset:33)
          element: <testLibrary>::@extensionType::X
          fields
            #F2 it (nameOffset:39) (firstTokenOffset:34) (offset:39)
              element: <testLibrary>::@extensionType::X::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@extensionType::X::@getter::it
      typeAliases
        #F4 A (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::A
  extensionTypes
    extension type X
      reference: <testLibrary>::@extensionType::X
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::X::@field::it
      primaryConstructor: <testLibrary>::@extensionType::X::@constructor::new
      typeErasure: int
      interfaces
        num
      fields
        final it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::X::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::X::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::X::@field::it
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F4
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
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F0
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final promotable _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
  fieldNameNonPromotabilityInfo
    _it
      conflictingFields
        <testLibrary>::@class::B::@field::_it
      conflictingGetters
        <testLibrary>::@class::C::@getter::_it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      extensionTypes
        #F1 extension type A (nameOffset:37) (firstTokenOffset:17) (offset:37)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:43) (firstTokenOffset:38) (offset:43)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:38) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 37
              formalParameters
                #F4 this.it (nameOffset:43) (firstTokenOffset:38) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F4 foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              formalParameters
                #F5 a (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@method::foo::@formalParameter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F5
              type: int
          returnType: void
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F4 foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              formalParameters
                #F5 a (nameOffset:43) (firstTokenOffset:39) (offset:43)
                  element: <testLibrary>::@extensionType::A::@method::foo::@formalParameter::a
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @47
                      staticType: int
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed a
              firstFragment: #F5
              type: int
              constantInitializer
                fragment: #F5
                expression: expression_0
          returnType: void
''');
  }

  test_missingName() async {
    var library = await buildLibrary(r'''
extension type (int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@extensionType::0
          fields
            #F2 it (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@extensionType::0::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@extensionType::0::@getter::it
  extensionTypes
    extension type <null-name>
      reference: <testLibrary>::@extensionType::0
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::0::@field::it
      primaryConstructor: <testLibrary>::@extensionType::0::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::0::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::0::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::0::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::0::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 <null-name> (nameOffset:<null>) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 16
              codeLength: 2
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 this.<null-name> (nameOffset:<null>) (firstTokenOffset:16) (offset:16)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::<null-name>
          getters
            #F5 synthetic <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType <null-name>
              firstFragment: #F4
              type: InvalidType
      getters
        synthetic isExtensionTypeMember <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          fields
            #F3 it (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    notSimplyBounded extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: A<dynamic>
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          setters
            #F5 foo (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F6 _ (nameOffset:44) (firstTokenOffset:37) (offset:44)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: double
          setter: <testLibrary>::@extensionType::A::@setter::foo
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F6
              type: double
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:19) (firstTokenOffset:16) (offset:19)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 it (nameOffset:46) (firstTokenOffset:43) (offset:46)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    hasRepresentationSelfReference extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::it
    hasRepresentationSelfReference extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: InvalidType
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: InvalidType
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::B::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:19) (firstTokenOffset:16) (offset:19)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 it (nameOffset:52) (firstTokenOffset:43) (offset:52)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: B
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: B
          variable: <testLibrary>::@extensionType::A::@field::it
    hasRepresentationSelfReference extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: InvalidType
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: InvalidType
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::B::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:19) (firstTokenOffset:16) (offset:19)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    hasRepresentationSelfReference extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 it (nameOffset:62) (firstTokenOffset:45) (offset:62)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int Function(int)
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: A Function(A)
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: A Function(A)
          variable: <testLibrary>::@extensionType::B::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          fields
            #F3 it (nameOffset:22) (firstTokenOffset:19) (offset:22)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F5 extension type B (nameOffset:45) (firstTokenOffset:30) (offset:45)
          element: <testLibrary>::@extensionType::B
          fields
            #F6 it (nameOffset:57) (firstTokenOffset:46) (offset:57)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F7 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: T
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F5
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: double
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F6
          type: A<double>
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F7
          returnType: A<double>
          variable: <testLibrary>::@extensionType::B::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 it (nameOffset:54) (firstTokenOffset:45) (offset:54)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F4
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: List<int>
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: List<A>
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@extensionType::B::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_typeParameters() async {
    var library = await buildLibrary(r'''
extension type A<T extends num, U>(Map<T, U> it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
            #F3 U (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: #E1 U
          fields
            #F4 it (nameOffset:45) (firstTokenOffset:34) (offset:45)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:34) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 this.it (nameOffset:45) (firstTokenOffset:34) (offset:45)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F7 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: num
        #E1 U
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Map<T, U>
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: Map<T, U>
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: Map<T, U>
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: Map<T, U>
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }
}

abstract class ExtensionTypeElementTest_augmentation extends ElementsBaseTest {
  test_augmentationTarget() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

augment extension type A(int it) {}

augment extension type A(int it) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:52) (firstTokenOffset:29) (offset:52)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F9
          fields
            #F4 augment it (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F10
          constructors
            #F7 augment new (nameOffset:<null>) (firstTokenOffset:53) (offset:52)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 52
              formalParameters
                #F11 this.it (nameOffset:58) (firstTokenOffset:53) (offset:58)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F12
              previousFragment: #F5
        #F9 extension type A (nameOffset:89) (firstTokenOffset:66) (offset:89)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F10 augment it (nameOffset:95) (firstTokenOffset:90) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F12 augment new (nameOffset:<null>) (firstTokenOffset:90) (offset:89)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 89
              formalParameters
                #F13 this.it (nameOffset:95) (firstTokenOffset:90) (offset:95)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
  exportedReferences
    declared <testLibrary>::@extensionType::A
  exportNamespace
    A: <testLibrary>::@extensionType::A
''');
  }

  test_augmentationTarget_no2() async {
    var library = await buildLibrary(r'''
augment extension type A(int it) {
  void foo1() {}
}

augment extension type A(int it) {
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:23) (firstTokenOffset:0) (offset:23)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 augment it (nameOffset:29) (firstTokenOffset:24) (offset:29)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 augment new (nameOffset:<null>) (firstTokenOffset:24) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 23
              formalParameters
                #F6 this.it (nameOffset:29) (firstTokenOffset:24) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F9 foo1 (nameOffset:42) (firstTokenOffset:37) (offset:42)
              element: <testLibrary>::@extensionType::A::@method::foo1
        #F2 extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:84) (firstTokenOffset:79) (offset:84)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F7 augment new (nameOffset:<null>) (firstTokenOffset:79) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F10 this.it (nameOffset:84) (firstTokenOffset:79) (offset:84)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F5
          methods
            #F11 foo2 (nameOffset:97) (firstTokenOffset:92) (offset:97)
              element: <testLibrary>::@extensionType::A::@method::foo2
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: #F9
          returnType: void
        isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@method::foo2
          firstFragment: #F11
          returnType: void
''');
  }

  test_augmented_constructors_add_named() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

augment extension type A(int it) {
  A.named();
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:52) (firstTokenOffset:29) (offset:52)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F7 augment new (nameOffset:<null>) (firstTokenOffset:53) (offset:52)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 52
              formalParameters
                #F9 this.it (nameOffset:58) (firstTokenOffset:53) (offset:58)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F5
            #F10 named (nameOffset:68) (firstTokenOffset:66) (offset:68)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 66
              periodOffset: 67
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
        isExtensionTypeMember named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F10
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_augmented_constructors_add_named_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {}

augment extension type A<T>(int it) {
  A.named(T a);
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 it (nameOffset:24) (firstTokenOffset:19) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:19) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:24) (firstTokenOffset:19) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:55) (firstTokenOffset:32) (offset:55)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment it (nameOffset:64) (firstTokenOffset:59) (offset:64)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:59) (offset:55)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 55
              formalParameters
                #F11 this.it (nameOffset:64) (firstTokenOffset:59) (offset:64)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
            #F12 named (nameOffset:74) (firstTokenOffset:72) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 72
              periodOffset: 73
              formalParameters
                #F13 a (nameOffset:82) (firstTokenOffset:80) (offset:82)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
        isExtensionTypeMember named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F12
          formalParameters
            #E2 requiredPositional a
              firstFragment: #F13
              type: T
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_augmented_constructors_add_unnamed_hasNamed() async {
    var library = await buildLibrary(r'''
extension type A.named(int it) {}

augment extension type A.named(int it) {
  A();
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:27) (firstTokenOffset:16) (offset:27)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 named (nameOffset:17) (firstTokenOffset:16) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F6 this.it (nameOffset:27) (firstTokenOffset:16) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:58) (firstTokenOffset:35) (offset:58)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:70) (firstTokenOffset:59) (offset:70)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F7 augment named (nameOffset:60) (firstTokenOffset:59) (offset:60)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 58
              periodOffset: 59
              formalParameters
                #F9 this.it (nameOffset:70) (firstTokenOffset:59) (offset:70)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
              previousFragment: #F5
            #F10 new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::named
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_augmented_field_augment_field() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F12 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F6 augment hasInitializer foo (nameOffset:108) (firstTokenOffset:108) (offset:108)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:76) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F14 this.it (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_field_augment_field2() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int foo = 1;
}

augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F12 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F14
          fields
            #F4 augment it (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F15
            #F6 augment hasInitializer foo (nameOffset:108) (firstTokenOffset:108) (offset:108)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
              nextFragment: #F16
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:76) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F17 this.it (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F18
              previousFragment: #F7
        #F14 extension type A (nameOffset:143) (firstTokenOffset:120) (offset:143)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F15 augment it (nameOffset:149) (firstTokenOffset:144) (offset:149)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
            #F16 augment hasInitializer foo (nameOffset:176) (firstTokenOffset:176) (offset:176)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F6
          constructors
            #F18 augment new (nameOffset:<null>) (firstTokenOffset:144) (offset:143)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 143
              formalParameters
                #F19 this.it (nameOffset:149) (firstTokenOffset:144) (offset:149)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F9
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int get foo => 1;
}

augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F12
          setters
            #F13 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F14 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F15
          fields
            #F4 augment it (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F16
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:76) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F17 this.it (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F18
              previousFragment: #F7
          getters
            #F12 augment foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F11
        #F15 extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F16 augment it (nameOffset:154) (firstTokenOffset:149) (offset:154)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
            #F6 augment hasInitializer foo (nameOffset:181) (firstTokenOffset:181) (offset:181)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F18 augment new (nameOffset:<null>) (firstTokenOffset:149) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F19 this.it (nameOffset:154) (firstTokenOffset:149) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F9
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static set foo(int _) {}
}

augment extension type A(int it) {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F12 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
              nextFragment: #F14
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F15
          fields
            #F4 augment it (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F16
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:76) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F17 this.it (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F18
              previousFragment: #F7
          setters
            #F14 augment foo (nameOffset:108) (firstTokenOffset:89) (offset:108)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F19 _ (nameOffset:116) (firstTokenOffset:112) (offset:116)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
              previousFragment: #F12
        #F15 extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F16 augment it (nameOffset:154) (firstTokenOffset:149) (offset:154)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
            #F6 augment hasInitializer foo (nameOffset:181) (firstTokenOffset:181) (offset:181)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F18 augment new (nameOffset:<null>) (firstTokenOffset:149) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F20 this.it (nameOffset:154) (firstTokenOffset:149) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F9
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static double foo = 1.2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F12 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F6 augment hasInitializer foo (nameOffset:111) (firstTokenOffset:111) (offset:111)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:76) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F14 this.it (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int get foo => 0;
}

augment extension type A(int it) {
  augment static int foo = 1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 foo (nameOffset:44) (firstTokenOffset:29) (offset:44)
              element: <testLibrary>::@extensionType::A::@getter::foo
        #F2 extension type A (nameOffset:80) (firstTokenOffset:57) (offset:80)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:86) (firstTokenOffset:81) (offset:86)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F6 augment hasInitializer foo (nameOffset:113) (firstTokenOffset:113) (offset:113)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:81) (offset:80)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 80
              formalParameters
                #F12 this.it (nameOffset:86) (firstTokenOffset:81) (offset:86)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_fields_add() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo1 = 0;
}

augment extension type A(int it) {
  static int foo2 = 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo1 (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F8
          getters
            #F9 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F10 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo1
          setters
            #F11 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::value
        #F2 extension type A (nameOffset:76) (firstTokenOffset:53) (offset:76)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:82) (firstTokenOffset:77) (offset:82)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F13 hasInitializer foo2 (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F8 augment new (nameOffset:<null>) (firstTokenOffset:77) (offset:76)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 76
              formalParameters
                #F14 this.it (nameOffset:82) (firstTokenOffset:77) (offset:82)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F6
          getters
            #F15 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@extensionType::A::@getter::foo2
          setters
            #F16 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              formalParameters
                #F17 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::value
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        static hasInitializer foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F13
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F7
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        synthetic static isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo2
      setters
        synthetic static isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        synthetic static isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@setter::foo2
          firstFragment: #F16
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F17
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_augmented_getters_add() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo1 => 0;
}

augment extension type A(int it) {
  int get foo2 => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F8
          getters
            #F9 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F10 foo1 (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo1
        #F2 extension type A (nameOffset:74) (firstTokenOffset:51) (offset:74)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:80) (firstTokenOffset:75) (offset:80)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F11 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F8 augment new (nameOffset:<null>) (firstTokenOffset:75) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 74
              formalParameters
                #F12 this.it (nameOffset:80) (firstTokenOffset:75) (offset:80)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F6
          getters
            #F13 foo2 (nameOffset:96) (firstTokenOffset:88) (offset:96)
              element: <testLibrary>::@extensionType::A::@getter::foo2
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F7
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {
  T get foo1;
}

augment extension type A<T>(int it) {
  T get foo2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 it (nameOffset:24) (firstTokenOffset:19) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
            #F7 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F8 new (nameOffset:<null>) (firstTokenOffset:19) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 this.it (nameOffset:24) (firstTokenOffset:19) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F10
          getters
            #F11 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F12 foo1 (nameOffset:38) (firstTokenOffset:32) (offset:38)
              element: <testLibrary>::@extensionType::A::@getter::foo1
        #F2 extension type A (nameOffset:70) (firstTokenOffset:47) (offset:70)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:72) (firstTokenOffset:72) (offset:72)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment it (nameOffset:79) (firstTokenOffset:74) (offset:79)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
            #F13 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F10 augment new (nameOffset:<null>) (firstTokenOffset:74) (offset:70)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 70
              formalParameters
                #F14 this.it (nameOffset:79) (firstTokenOffset:74) (offset:79)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F8
          getters
            #F15 foo2 (nameOffset:93) (firstTokenOffset:87) (offset:93)
              element: <testLibrary>::@extensionType::A::@getter::foo2
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional final hasImplicitType it
              firstFragment: #F9
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        abstract isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::foo1
        abstract isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F15
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_augmented_getters_augment_field() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F8
          getters
            #F9 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F10 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F11
          setters
            #F12 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F8 augment new (nameOffset:<null>) (firstTokenOffset:76) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F14 this.it (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F6
          getters
            #F11 augment foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F10
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F7
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_getters_augment_field2() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static int get foo => 0;
}

augment extension type A(int it) {
  augment static int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F8
          getters
            #F9 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F10 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F11
          setters
            #F12 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F14
          fields
            #F4 augment it (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F15
          constructors
            #F8 augment new (nameOffset:<null>) (firstTokenOffset:76) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F16 this.it (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F17
              previousFragment: #F6
          getters
            #F11 augment foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F10
              nextFragment: #F18
        #F14 extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F15 augment it (nameOffset:154) (firstTokenOffset:149) (offset:154)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F17 augment new (nameOffset:<null>) (firstTokenOffset:149) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F19 this.it (nameOffset:154) (firstTokenOffset:149) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F8
          getters
            #F18 augment foo (nameOffset:185) (firstTokenOffset:162) (offset:185)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F11
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F7
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_getters_augment_getter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo1 => 0;
  int get foo2 => 0;
}

augment extension type A(int it) {
  augment int get foo1 => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
            #F6 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 foo1 (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo1
              nextFragment: #F12
            #F13 foo2 (nameOffset:58) (firstTokenOffset:50) (offset:58)
              element: <testLibrary>::@extensionType::A::@getter::foo2
        #F2 extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:101) (firstTokenOffset:96) (offset:101)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:96) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F14 this.it (nameOffset:101) (firstTokenOffset:96) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
          getters
            #F12 augment foo1 (nameOffset:125) (firstTokenOffset:109) (offset:125)
              element: <testLibrary>::@extensionType::A::@getter::foo1
              previousFragment: #F11
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_augmented_getters_augment_getter2() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  int get foo => 0;
}

augment extension type A(int it) {
  augment int get foo => 0;
}

augment extension type A(int it) {
  augment int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F8
          getters
            #F9 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F10 foo (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F11
        #F2 extension type A (nameOffset:73) (firstTokenOffset:50) (offset:73)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F12
          fields
            #F4 augment it (nameOffset:79) (firstTokenOffset:74) (offset:79)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F13
          constructors
            #F8 augment new (nameOffset:<null>) (firstTokenOffset:74) (offset:73)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 73
              formalParameters
                #F14 this.it (nameOffset:79) (firstTokenOffset:74) (offset:79)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F15
              previousFragment: #F6
          getters
            #F11 augment foo (nameOffset:103) (firstTokenOffset:87) (offset:103)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F10
              nextFragment: #F16
        #F12 extension type A (nameOffset:139) (firstTokenOffset:116) (offset:139)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F13 augment it (nameOffset:145) (firstTokenOffset:140) (offset:145)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F15 augment new (nameOffset:<null>) (firstTokenOffset:140) (offset:139)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 139
              formalParameters
                #F17 this.it (nameOffset:145) (firstTokenOffset:140) (offset:145)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F8
          getters
            #F16 augment foo (nameOffset:169) (firstTokenOffset:153) (offset:169)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F11
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F7
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_interfaces() async {
    configuration.withConstructors = false;
    var library = await buildLibrary(r'''
extension type A(int it) implements I1 {}
extension type I1(int it) {}

augment extension type A(int it) implements I2 {}
extension type I2(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F6 extension type I1 (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@extensionType::I1
          fields
            #F7 it (nameOffset:64) (firstTokenOffset:59) (offset:64)
              element: <testLibrary>::@extensionType::I1::@field::it
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@extensionType::I1::@getter::it
        #F2 extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:101) (firstTokenOffset:96) (offset:101)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
        #F9 extension type I2 (nameOffset:137) (firstTokenOffset:122) (offset:137)
          element: <testLibrary>::@extensionType::I2
          fields
            #F10 it (nameOffset:144) (firstTokenOffset:139) (offset:144)
              element: <testLibrary>::@extensionType::I2::@field::it
          getters
            #F11 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:144)
              element: <testLibrary>::@extensionType::I2::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        I1
        I2
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F9
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
''');
  }

  test_augmented_interfaces_chain() async {
    var library = await buildLibrary(r'''
extension type A(int it) implements I1 {}
extension type I1(int it) {}

augment extension type A(int it) implements I2 {}
extension type I2(int it) {}

augment extension type A(int it) implements I3 {}
extension type I3(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F9 extension type I1 (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@extensionType::I1
          fields
            #F10 it (nameOffset:64) (firstTokenOffset:59) (offset:64)
              element: <testLibrary>::@extensionType::I1::@field::it
          constructors
            #F11 new (nameOffset:<null>) (firstTokenOffset:59) (offset:57)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 57
              formalParameters
                #F12 this.it (nameOffset:64) (firstTokenOffset:59) (offset:64)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F13 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@extensionType::I1::@getter::it
        #F2 extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F14
          fields
            #F4 augment it (nameOffset:101) (firstTokenOffset:96) (offset:101)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F15
          constructors
            #F7 augment new (nameOffset:<null>) (firstTokenOffset:96) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F16 this.it (nameOffset:101) (firstTokenOffset:96) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F17
              previousFragment: #F5
        #F18 extension type I2 (nameOffset:137) (firstTokenOffset:122) (offset:137)
          element: <testLibrary>::@extensionType::I2
          fields
            #F19 it (nameOffset:144) (firstTokenOffset:139) (offset:144)
              element: <testLibrary>::@extensionType::I2::@field::it
          constructors
            #F20 new (nameOffset:<null>) (firstTokenOffset:139) (offset:137)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 137
              formalParameters
                #F21 this.it (nameOffset:144) (firstTokenOffset:139) (offset:144)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F22 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:144)
              element: <testLibrary>::@extensionType::I2::@getter::it
        #F14 extension type A (nameOffset:175) (firstTokenOffset:152) (offset:175)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F15 augment it (nameOffset:181) (firstTokenOffset:176) (offset:181)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F17 augment new (nameOffset:<null>) (firstTokenOffset:176) (offset:175)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 175
              formalParameters
                #F23 this.it (nameOffset:181) (firstTokenOffset:176) (offset:181)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
        #F24 extension type I3 (nameOffset:217) (firstTokenOffset:202) (offset:217)
          element: <testLibrary>::@extensionType::I3
          fields
            #F25 it (nameOffset:224) (firstTokenOffset:219) (offset:224)
              element: <testLibrary>::@extensionType::I3::@field::it
          constructors
            #F26 new (nameOffset:<null>) (firstTokenOffset:219) (offset:217)
              element: <testLibrary>::@extensionType::I3::@constructor::new
              typeName: I3
              typeNameOffset: 217
              formalParameters
                #F27 this.it (nameOffset:224) (firstTokenOffset:219) (offset:224)
                  element: <testLibrary>::@extensionType::I3::@constructor::new::@formalParameter::it
          getters
            #F28 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:224)
              element: <testLibrary>::@extensionType::I3::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        I1
        I2
        I3
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F9
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional final hasImplicitType it
              firstFragment: #F12
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F18
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F20
          formalParameters
            #E2 requiredPositional final hasImplicitType it
              firstFragment: #F21
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F22
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
    extension type I3
      reference: <testLibrary>::@extensionType::I3
      firstFragment: #F24
      representation: <testLibrary>::@extensionType::I3::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I3::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I3::@field::it
          firstFragment: #F25
          type: int
          getter: <testLibrary>::@extensionType::I3::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::I3::@constructor::new
          firstFragment: #F26
          formalParameters
            #E3 requiredPositional final hasImplicitType it
              firstFragment: #F27
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I3::@getter::it
          firstFragment: #F28
          returnType: int
          variable: <testLibrary>::@extensionType::I3::@field::it
''');
  }

  test_augmented_interfaces_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) implements I1 {}
extension type I1(int it) {}

augment extension type A<T>(int it) implements I2<T> {}
extension type I2<E>(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 it (nameOffset:24) (firstTokenOffset:19) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:19) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:24) (firstTokenOffset:19) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F11 extension type I1 (nameOffset:60) (firstTokenOffset:45) (offset:60)
          element: <testLibrary>::@extensionType::I1
          fields
            #F12 it (nameOffset:67) (firstTokenOffset:62) (offset:67)
              element: <testLibrary>::@extensionType::I1::@field::it
          constructors
            #F13 new (nameOffset:<null>) (firstTokenOffset:62) (offset:60)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 60
              formalParameters
                #F14 this.it (nameOffset:67) (firstTokenOffset:62) (offset:67)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F15 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@extensionType::I1::@getter::it
        #F2 extension type A (nameOffset:98) (firstTokenOffset:75) (offset:98)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment it (nameOffset:107) (firstTokenOffset:102) (offset:107)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:102) (offset:98)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 98
              formalParameters
                #F16 this.it (nameOffset:107) (firstTokenOffset:102) (offset:107)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
        #F17 extension type I2 (nameOffset:146) (firstTokenOffset:131) (offset:146)
          element: <testLibrary>::@extensionType::I2
          typeParameters
            #F18 E (nameOffset:149) (firstTokenOffset:149) (offset:149)
              element: #E1 E
          fields
            #F19 it (nameOffset:156) (firstTokenOffset:151) (offset:156)
              element: <testLibrary>::@extensionType::I2::@field::it
          constructors
            #F20 new (nameOffset:<null>) (firstTokenOffset:151) (offset:146)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 146
              formalParameters
                #F21 this.it (nameOffset:156) (firstTokenOffset:151) (offset:156)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F22 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:156)
              element: <testLibrary>::@extensionType::I2::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        I1
        I2<T>
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E2 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F11
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F12
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F13
          formalParameters
            #E3 requiredPositional final hasImplicitType it
              firstFragment: #F14
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F17
      typeParameters
        #E1 E
          firstFragment: #F18
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F20
          formalParameters
            #E4 requiredPositional final hasImplicitType it
              firstFragment: #F21
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F22
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
''');
  }

  test_augmented_interfaces_generic_mismatch() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) implements I1 {}
extension type I1(int it) {}

augment extension type A<T, U>(int it) implements I2<T> {}
extension type I2<E>(int it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 it (nameOffset:24) (firstTokenOffset:19) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:19) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:24) (firstTokenOffset:19) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F11 extension type I1 (nameOffset:60) (firstTokenOffset:45) (offset:60)
          element: <testLibrary>::@extensionType::I1
          fields
            #F12 it (nameOffset:67) (firstTokenOffset:62) (offset:67)
              element: <testLibrary>::@extensionType::I1::@field::it
          constructors
            #F13 new (nameOffset:<null>) (firstTokenOffset:62) (offset:60)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 60
              formalParameters
                #F14 this.it (nameOffset:67) (firstTokenOffset:62) (offset:67)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F15 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@extensionType::I1::@getter::it
        #F2 extension type A (nameOffset:98) (firstTokenOffset:75) (offset:98)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment it (nameOffset:110) (firstTokenOffset:105) (offset:110)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:105) (offset:98)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 98
              formalParameters
                #F16 this.it (nameOffset:110) (firstTokenOffset:105) (offset:110)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
        #F17 extension type I2 (nameOffset:149) (firstTokenOffset:134) (offset:149)
          element: <testLibrary>::@extensionType::I2
          typeParameters
            #F18 E (nameOffset:152) (firstTokenOffset:152) (offset:152)
              element: #E1 E
          fields
            #F19 it (nameOffset:159) (firstTokenOffset:154) (offset:159)
              element: <testLibrary>::@extensionType::I2::@field::it
          constructors
            #F20 new (nameOffset:<null>) (firstTokenOffset:154) (offset:149)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 149
              formalParameters
                #F21 this.it (nameOffset:159) (firstTokenOffset:154) (offset:159)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F22 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:159)
              element: <testLibrary>::@extensionType::I2::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      interfaces
        I1
        I2<T>
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E2 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F11
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F12
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F13
          formalParameters
            #E3 requiredPositional final hasImplicitType it
              firstFragment: #F14
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F17
      typeParameters
        #E1 E
          firstFragment: #F18
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F20
          formalParameters
            #E4 requiredPositional final hasImplicitType it
              firstFragment: #F21
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F22
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
''');
  }

  test_augmented_methods() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

augment extension type A(int it) {
  void bar() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F9 foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
        #F2 extension type A (nameOffset:69) (firstTokenOffset:46) (offset:69)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:75) (firstTokenOffset:70) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F7 augment new (nameOffset:<null>) (firstTokenOffset:70) (offset:69)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 69
              formalParameters
                #F10 this.it (nameOffset:75) (firstTokenOffset:70) (offset:75)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F5
          methods
            #F11 bar (nameOffset:88) (firstTokenOffset:83) (offset:88)
              element: <testLibrary>::@extensionType::A::@method::bar
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F9
          returnType: void
        isExtensionTypeMember bar
          reference: <testLibrary>::@extensionType::A::@method::bar
          firstFragment: #F11
          returnType: void
''');
  }

  test_augmented_methods_augment() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo1() {}
  void foo2() {}
}

augment extension type A(int it) {
  augment void foo1() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F9 foo1 (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo1
              nextFragment: #F10
            #F11 foo2 (nameOffset:51) (firstTokenOffset:46) (offset:51)
              element: <testLibrary>::@extensionType::A::@method::foo2
        #F2 extension type A (nameOffset:87) (firstTokenOffset:64) (offset:87)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:93) (firstTokenOffset:88) (offset:93)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F7 augment new (nameOffset:<null>) (firstTokenOffset:88) (offset:87)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 87
              formalParameters
                #F12 this.it (nameOffset:93) (firstTokenOffset:88) (offset:93)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F5
          methods
            #F10 augment foo1 (nameOffset:114) (firstTokenOffset:101) (offset:114)
              element: <testLibrary>::@extensionType::A::@method::foo1
              previousFragment: #F9
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: #F9
          returnType: void
        isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@method::foo2
          firstFragment: #F11
          returnType: void
''');
  }

  test_augmented_methods_augment2() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
}

augment extension type A(int it) {
  augment void foo() {}
}

augment extension type A(int it) {
  augment void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F9 foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F10
        #F2 extension type A (nameOffset:69) (firstTokenOffset:46) (offset:69)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F11
          fields
            #F4 augment it (nameOffset:75) (firstTokenOffset:70) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F12
          constructors
            #F7 augment new (nameOffset:<null>) (firstTokenOffset:70) (offset:69)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 69
              formalParameters
                #F13 this.it (nameOffset:75) (firstTokenOffset:70) (offset:75)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F14
              previousFragment: #F5
          methods
            #F10 augment foo (nameOffset:96) (firstTokenOffset:83) (offset:96)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F9
              nextFragment: #F15
        #F11 extension type A (nameOffset:131) (firstTokenOffset:108) (offset:131)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F12 augment it (nameOffset:137) (firstTokenOffset:132) (offset:137)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F14 augment new (nameOffset:<null>) (firstTokenOffset:132) (offset:131)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 131
              formalParameters
                #F16 this.it (nameOffset:137) (firstTokenOffset:132) (offset:137)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
          methods
            #F15 augment foo (nameOffset:158) (firstTokenOffset:145) (offset:158)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F10
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F9
          returnType: void
''');
  }

  test_augmented_methods_generic() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {
  T foo() => throw 0;
}

augment extension type A<T>(int it) {
  T bar() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 it (nameOffset:24) (firstTokenOffset:19) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:19) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:24) (firstTokenOffset:19) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F11 foo (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
        #F2 extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment it (nameOffset:87) (firstTokenOffset:82) (offset:87)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:82) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F12 this.it (nameOffset:87) (firstTokenOffset:82) (offset:87)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
          methods
            #F13 bar (nameOffset:97) (firstTokenOffset:95) (offset:97)
              element: <testLibrary>::@extensionType::A::@method::bar
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          returnType: T
        isExtensionTypeMember bar
          reference: <testLibrary>::@extensionType::A::@method::bar
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_methods_generic_augment() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {
  T foo() => throw 0;
}

augment extension type A<T>(int it) {
  augment T foo() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 it (nameOffset:24) (firstTokenOffset:19) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:19) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:24) (firstTokenOffset:19) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F11 foo (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F12
        #F2 extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment it (nameOffset:87) (firstTokenOffset:82) (offset:87)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:82) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F13 this.it (nameOffset:87) (firstTokenOffset:82) (offset:87)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
          methods
            #F12 augment foo (nameOffset:105) (firstTokenOffset:95) (offset:105)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F11
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_methods_typeParameterCountMismatch() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  void foo() {}
  void bar() {}
}

augment extension type A<T>(int it) {
  augment void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F7
          getters
            #F8 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F9 foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F10
            #F11 bar (nameOffset:50) (firstTokenOffset:45) (offset:50)
              element: <testLibrary>::@extensionType::A::@method::bar
        #F2 extension type A (nameOffset:85) (firstTokenOffset:62) (offset:85)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:94) (firstTokenOffset:89) (offset:94)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F7 augment new (nameOffset:<null>) (firstTokenOffset:89) (offset:85)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 85
              formalParameters
                #F12 this.it (nameOffset:94) (firstTokenOffset:89) (offset:94)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F5
          methods
            #F10 augment foo (nameOffset:115) (firstTokenOffset:102) (offset:115)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F9
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F6
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F9
          returnType: void
        isExtensionTypeMember bar
          reference: <testLibrary>::@extensionType::A::@method::bar
          firstFragment: #F11
          returnType: void
''');
  }

  test_augmented_setters_add() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo1(int _) {}
}

augment extension type A(int it) {
  set foo2(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F8
          getters
            #F9 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          setters
            #F10 foo1 (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F11 _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
        #F2 extension type A (nameOffset:74) (firstTokenOffset:51) (offset:74)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:80) (firstTokenOffset:75) (offset:80)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F12 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F8 augment new (nameOffset:<null>) (firstTokenOffset:75) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 74
              formalParameters
                #F13 this.it (nameOffset:80) (firstTokenOffset:75) (offset:80)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F6
          setters
            #F14 foo2 (nameOffset:92) (firstTokenOffset:88) (offset:92)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              formalParameters
                #F15 _ (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::_
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        synthetic foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F12
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F7
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@setter::foo2
          firstFragment: #F14
          formalParameters
            #E2 requiredPositional _
              firstFragment: #F15
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_augmented_setters_augment_field() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  static int foo = 0;
}

augment extension type A(int it) {
  augment static set foo(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F6 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F8
          getters
            #F9 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F10 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F11 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
              nextFragment: #F13
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:81) (firstTokenOffset:76) (offset:81)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F8 augment new (nameOffset:<null>) (firstTokenOffset:76) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F14 this.it (nameOffset:81) (firstTokenOffset:76) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F6
          setters
            #F13 augment foo (nameOffset:108) (firstTokenOffset:89) (offset:108)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F15 _ (nameOffset:116) (firstTokenOffset:112) (offset:116)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
              previousFragment: #F11
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        static hasInitializer foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F7
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        synthetic static isExtensionTypeMember foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo
''');
  }

  test_augmented_setters_augment_setter() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  set foo1(int _) {}
  set foo2(int _) {}
}

augment extension type A(int it) {
  augment set foo1(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
            #F6 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:16) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 this.it (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              nextFragment: #F9
          getters
            #F10 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
          setters
            #F11 foo1 (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F12 _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
              nextFragment: #F13
            #F14 foo2 (nameOffset:54) (firstTokenOffset:50) (offset:54)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              formalParameters
                #F15 _ (nameOffset:63) (firstTokenOffset:59) (offset:63)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::_
        #F2 extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment it (nameOffset:101) (firstTokenOffset:96) (offset:101)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F9 augment new (nameOffset:<null>) (firstTokenOffset:96) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F16 this.it (nameOffset:101) (firstTokenOffset:96) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              previousFragment: #F7
          setters
            #F13 augment foo1 (nameOffset:121) (firstTokenOffset:109) (offset:121)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F17 _ (nameOffset:130) (firstTokenOffset:126) (offset:130)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
              previousFragment: #F11
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
        synthetic foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        synthetic foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F8
              type: int
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember foo2
          reference: <testLibrary>::@extensionType::A::@setter::foo2
          firstFragment: #F14
          formalParameters
            #E2 requiredPositional _
              firstFragment: #F15
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo2
''');
  }

  test_augmentedBy_class2() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

augment class A {}

augment class A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
          nextFragment: #F2
        #F2 class A (nameOffset:63) (firstTokenOffset:49) (offset:63)
          element: <testLibrary>::@class::A
          previousFragment: #F1
      extensionTypes
        #F3 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F4 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_augmentedBy_class_extensionType() async {
    var library = await buildLibrary(r'''
extension type A(int it) {}

augment class A {}

augment extension type A(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@class::A
      extensionTypes
        #F2 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A::@def::0
          fields
            #F3 it (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@extensionType::A::@def::0::@field::it
          getters
            #F4 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@def::0::@getter::it
        #F5 extension type A (nameOffset:72) (firstTokenOffset:49) (offset:72)
          element: <testLibrary>::@extensionType::A::@def::1
          fields
            #F6 augment it (nameOffset:78) (firstTokenOffset:73) (offset:78)
              element: <testLibrary>::@extensionType::A::@def::1::@field::it
          getters
            #F7 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@def::1::@getter::it
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A::@def::0
      firstFragment: #F2
      representation: <testLibrary>::@extensionType::A::@def::0::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@def::0::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@def::0::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@def::0::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@def::0::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@def::0::@field::it
    extension type A
      reference: <testLibrary>::@extensionType::A::@def::1
      firstFragment: #F5
      representation: <testLibrary>::@extensionType::A::@def::1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@def::1::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@def::1::@field::it
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@def::1::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@def::1::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@def::1::@field::it
''');
  }

  test_typeParameters_111() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {}
augment extension type A<T>(int it) {}
augment extension type A<T>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 it (nameOffset:24) (firstTokenOffset:19) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          getters
            #F7 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:54) (firstTokenOffset:31) (offset:54)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F8
          typeParameters
            #F4 T (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F9
          fields
            #F6 augment it (nameOffset:63) (firstTokenOffset:58) (offset:63)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
              nextFragment: #F10
        #F8 extension type A (nameOffset:93) (firstTokenOffset:70) (offset:93)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F9 T (nameOffset:95) (firstTokenOffset:95) (offset:95)
              element: #E0 T
              previousFragment: #F4
          fields
            #F10 augment it (nameOffset:102) (firstTokenOffset:97) (offset:102)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F6
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_typeParameters_121() async {
    var library = await buildLibrary(r'''
extension type A<T>(int it) {}
augment extension type A<T, U>(int it) {}
augment extension type A<T>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 it (nameOffset:24) (firstTokenOffset:19) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          getters
            #F7 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:54) (firstTokenOffset:31) (offset:54)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F8
          typeParameters
            #F4 T (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F9
          fields
            #F6 augment it (nameOffset:66) (firstTokenOffset:61) (offset:66)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
              nextFragment: #F10
        #F8 extension type A (nameOffset:96) (firstTokenOffset:73) (offset:96)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F9 T (nameOffset:98) (firstTokenOffset:98) (offset:98)
              element: #E0 T
              previousFragment: #F4
          fields
            #F10 augment it (nameOffset:105) (firstTokenOffset:100) (offset:105)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F6
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_typeParameters_212() async {
    var library = await buildLibrary(r'''
extension type A<T, U>(int it) {}
augment extension type A<T>(int it) {}
augment extension type A<T, U>(int it) {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: #E1 U
              nextFragment: #F6
          fields
            #F7 it (nameOffset:27) (firstTokenOffset:22) (offset:27)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F8
          getters
            #F9 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:57) (firstTokenOffset:34) (offset:57)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F10
          typeParameters
            #F4 T (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F11
            #F6 U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F12
          fields
            #F8 augment it (nameOffset:66) (firstTokenOffset:61) (offset:66)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F7
              nextFragment: #F13
        #F10 extension type A (nameOffset:96) (firstTokenOffset:73) (offset:96)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          typeParameters
            #F11 T (nameOffset:98) (firstTokenOffset:98) (offset:98)
              element: #E0 T
              previousFragment: #F4
            #F12 U (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: #E1 U
              previousFragment: #F6
          fields
            #F13 augment it (nameOffset:108) (firstTokenOffset:103) (offset:108)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F8
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
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
