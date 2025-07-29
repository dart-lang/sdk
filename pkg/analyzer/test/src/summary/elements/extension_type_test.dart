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
    // TODO(scheglov): implement augmentation
    // defineReflectiveTests(ExtensionTypeElementTest_augmentation_keepLinking);
    // defineReflectiveTests(ExtensionTypeElementTest_augmentation_fromBytes);
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        augment A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
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
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        augment A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
          typeErasure: int
          fields
            final it @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
          constructors
            augment @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional final hasImplicitType this.it @65
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
          methods
            foo1 @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            foo2 @60
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          fields
            it @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
          constructors
            augment new
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new#element
              typeName: A
              typeNameOffset: 59
              formalParameters
                this.it @65
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it#element
          methods
            foo1 @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            foo2 @60
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@method::foo2#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
      representation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it#element
      primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::it
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::it
      methods
        foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::foo1
        foo2
          reference: <testLibrary>::@extensionType::A::@method::foo2
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            named @60
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          constructors
            named @60
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named#element
              typeName: A
              typeNameOffset: 58
              periodOffset: 59
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
        named
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
      getters
        synthetic get it
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @40
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            named @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T1 @32
              element: <not-implemented>
          fields
            it @40
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @40
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <not-implemented>
          constructors
            named @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named#element
              typeName: A
              typeNameOffset: 62
              periodOffset: 63
              formalParameters
                a @73
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named::@parameter::a#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeParameters
        T1
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
        named
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::named
          formalParameters
            requiredPositional a
              type: T2
      getters
        synthetic get it
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::named
          typeErasure: int
          fields
            final it @42
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            named @32
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              periodOffset: 31
              nameEnd: 37
              parameters
                requiredPositional final hasImplicitType this.it @42
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          constructors
            @58
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @42
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            named @32
              reference: <testLibraryFragment>::@extensionType::A::@constructor::named
              element: <testLibraryFragment>::@extensionType::A::@constructor::named#element
              typeName: A
              typeNameOffset: 30
              periodOffset: 31
              formalParameters
                this.it @42
                  element: <testLibraryFragment>::@extensionType::A::@constructor::named::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          constructors
            new
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new#element
              typeName: A
              typeNameOffset: 58
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::named#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        named
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::named
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
        new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@constructor::new
      getters
        synthetic get it
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            augment hasInitializer foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 45
              formalParameters
                this.it @51
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          fields
            augment hasInitializer foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment hasInitializer foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 45
              formalParameters
                this.it @51
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment hasInitializer foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static set foo= @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @85
                  type: int
              returnType: void
              id: setter_1
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 45
              formalParameters
                this.it @51
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          setters
            augment set foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _ @85
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo::@parameter::_#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            augment hasInitializer foo @77
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            augment hasInitializer foo @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic static foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            static get foo @59
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            augment static foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            synthetic foo
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            get foo @59
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            augment hasInitializer foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@field::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        synthetic static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        static get foo
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo1 @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo1= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            static foo2 @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              setter: setter_1
          accessors
            synthetic static get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: field_2
            synthetic static set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo1 @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <testLibraryFragment>::@extensionType::A::@field::foo1#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo1
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo1
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              element: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
          setters
            synthetic set foo1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              element: <testLibraryFragment>::@extensionType::A::@setter::foo1#element
              formalParameters
                _foo1
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo1::@parameter::_foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            hasInitializer foo2 @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              setter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
          getters
            synthetic get foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2#element
          setters
            synthetic set foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2#element
              formalParameters
                _foo2
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2::@parameter::_foo2#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo1#element
        static hasInitializer foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2#element
          setter: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
        synthetic static get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
      setters
        synthetic static set foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo1
          formalParameters
            requiredPositional _foo1
              type: int
        synthetic static set foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
          formalParameters
            requiredPositional _foo2
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo1 @52
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              id: field_2
              getter: getter_2
          accessors
            get foo2 @66
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            synthetic foo1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <testLibraryFragment>::@extensionType::A::@field::foo1#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo1
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            get foo1 @52
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              element: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
          getters
            get foo2 @66
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        get foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
        get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension type A<T1>(int it) {
  T1 get foo2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension type A<T1>(int it) {
  T1 get foo1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: T1
              id: field_1
              getter: getter_1
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @40
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            abstract get foo1 @55
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: T1
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extensionType::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
                augmentationSubstitution: {T1: T1}
              <testLibraryFragment>::@extensionType::A::@field::it
            constructors
              <testLibraryFragment>::@extensionType::A::@constructor::new
            accessors
              <testLibraryFragment>::@extensionType::A::@getter::foo1
              GetterMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
                augmentationSubstitution: {T1: T1}
              <testLibraryFragment>::@extensionType::A::@getter::it
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T1 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: T1
              id: field_2
              getter: getter_2
          accessors
            abstract get foo2 @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: T1
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T1 @32
              element: <not-implemented>
          fields
            it @40
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            synthetic foo1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <testLibraryFragment>::@extensionType::A::@field::foo1#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo1
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @40
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            get foo1 @55
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              element: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T1 @46
              element: <not-implemented>
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
          getters
            get foo2 @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeParameters
        T1
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          type: T1
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
          type: T1
          getter: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getter::foo2#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        abstract get foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
        abstract get foo2
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment static get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: <null>
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          getters
            augment get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          accessors
            augment static get foo @81
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: <null>
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo @70
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 45
              formalParameters
                this.it @51
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @81
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo1 @52
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
            get foo2 @73
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo2
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment get foo1 @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: <null>
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            synthetic foo1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <testLibraryFragment>::@extensionType::A::@field::foo1#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo1
            synthetic foo2
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              element: <testLibraryFragment>::@extensionType::A::@field::foo2#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo2
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            get foo1 @52
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo1
              element: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
            get foo2 @73
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo2
              element: <testLibraryFragment>::@extensionType::A::@getter::foo2#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          getters
            augment get foo1 @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo1
              element: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo2
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo2#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        get foo2
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo2
        get foo1
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @45
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              getter: getter_1
          constructors
            @45
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @51
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            get foo @67
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          accessors
            augment get foo @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_2
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          accessors
            augment get foo @74
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: int
              id: getter_3
              variable: <null>
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @51
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            synthetic foo
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 45
              formalParameters
                this.it @51
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            get foo @67
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          getters
            augment get foo @74
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@getterAugmentation::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        synthetic foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        get foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @79
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          interfaces
            I2
        I2 @86
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @93
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
        extension type I1 @72
          reference: <testLibraryFragment>::@extensionType::I1
          element: <testLibrary>::@extensionType::I1
          fields
            it @79
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              element: <testLibraryFragment>::@extensionType::I1::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::I1::@getter::it
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              element: <testLibraryFragment>::@extensionType::I1::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
        extension type I2 @86
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          element: <testLibrary>::@extensionType::I2
          fields
            it @93
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
          getters
            synthetic get it
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      interfaces
        I1
        I2
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: <testLibraryFragment>::@extensionType::I1
      representation: <testLibraryFragment>::@extensionType::I1::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::I1::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::I1::@getter::it#element
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::I1::@getter::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it#element
      primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it#element
      getters
        synthetic get it
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          interfaces
            I1
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @79
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @72
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final hasImplicitType this.it @79
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        augment A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          interfaces
            I2
        I2 @101
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @108
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @101
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final hasImplicitType this.it @108
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              returnType: int
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          interfaces
            I3
        I3 @83
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          representation: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
          typeErasure: int
          fields
            final it @90
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
              type: int
          constructors
            @83
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
              parameters
                requiredPositional final hasImplicitType this.it @90
                  type: int
                  field: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
        extension type I1 @72
          reference: <testLibraryFragment>::@extensionType::I1
          element: <testLibrary>::@extensionType::I1
          fields
            it @79
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              element: <testLibraryFragment>::@extensionType::I1::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::I1::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              element: <testLibraryFragment>::@extensionType::I1::@constructor::new#element
              typeName: I1
              typeNameOffset: 72
              formalParameters
                this.it @79
                  element: <testLibraryFragment>::@extensionType::I1::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              element: <testLibraryFragment>::@extensionType::I1::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
        extension type I2 @101
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          element: <testLibrary>::@extensionType::I2
          fields
            it @108
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
          constructors
            new
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new#element
              typeName: I2
              typeNameOffset: 101
              formalParameters
                this.it @108
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
        extension type I3 @83
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
          element: <testLibrary>::@extensionType::I3
          fields
            it @90
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
              element: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it#element
              getter2: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it
          constructors
            new
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
              element: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new#element
              typeName: I3
              typeNameOffset: 83
              formalParameters
                this.it @90
                  element: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it
              element: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      interfaces
        I1
        I2
        I3
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: <testLibraryFragment>::@extensionType::I1
      representation: <testLibraryFragment>::@extensionType::I1::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::I1::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::I1::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::I1::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::I1::@getter::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it#element
      primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it#element
      constructors
        new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
    extension type I3
      reference: <testLibrary>::@extensionType::I3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3
      representation: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it#element
      primaryConstructor: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@field::it
          type: int
          getter: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@getter::it#element
      constructors
        new
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionType::I3::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @39
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @82
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @75
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final hasImplicitType this.it @82
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          interfaces
            I2<T2>
        I2 @94
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @97
              defaultType: dynamic
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @104
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @94
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final hasImplicitType this.it @104
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T @32
              element: <not-implemented>
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @39
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
        extension type I1 @75
          reference: <testLibraryFragment>::@extensionType::I1
          element: <testLibrary>::@extensionType::I1
          fields
            it @82
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              element: <testLibraryFragment>::@extensionType::I1::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::I1::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              element: <testLibraryFragment>::@extensionType::I1::@constructor::new#element
              typeName: I1
              typeNameOffset: 75
              formalParameters
                this.it @82
                  element: <testLibraryFragment>::@extensionType::I1::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              element: <testLibraryFragment>::@extensionType::I1::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <not-implemented>
        extension type I2 @94
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          element: <testLibrary>::@extensionType::I2
          typeParameters
            E @97
              element: <not-implemented>
          fields
            it @104
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
          constructors
            new
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new#element
              typeName: I2
              typeNameOffset: 94
              formalParameters
                this.it @104
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      interfaces
        I1
        I2<T>
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: <testLibraryFragment>::@extensionType::I1
      representation: <testLibraryFragment>::@extensionType::I1::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::I1::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::I1::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::I1::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::I1::@getter::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      typeParameters
        E
      representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it#element
      primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it#element
      constructors
        new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @39
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::I1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new
          typeErasure: int
          fields
            final it @82
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              type: int
          constructors
            @75
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              parameters
                requiredPositional final hasImplicitType this.it @82
                  type: int
                  field: <testLibraryFragment>::@extensionType::I1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::I1
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @101
              defaultType: dynamic
          representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          typeErasure: int
          fields
            final it @108
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              type: int
          constructors
            @98
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
              parameters
                requiredPositional final hasImplicitType this.it @108
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T @32
              element: <not-implemented>
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @39
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
        extension type I1 @75
          reference: <testLibraryFragment>::@extensionType::I1
          element: <testLibrary>::@extensionType::I1
          fields
            it @82
              reference: <testLibraryFragment>::@extensionType::I1::@field::it
              element: <testLibraryFragment>::@extensionType::I1::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::I1::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::I1::@constructor::new
              element: <testLibraryFragment>::@extensionType::I1::@constructor::new#element
              typeName: I1
              typeNameOffset: 75
              formalParameters
                this.it @82
                  element: <testLibraryFragment>::@extensionType::I1::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::I1::@getter::it
              element: <testLibraryFragment>::@extensionType::I1::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <not-implemented>
            T3 @50
              element: <not-implemented>
        extension type I2 @98
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
          element: <testLibrary>::@extensionType::I2
          typeParameters
            E @101
              element: <not-implemented>
          fields
            it @108
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
          constructors
            new
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new#element
              typeName: I2
              typeNameOffset: 98
              formalParameters
                this.it @108
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      interfaces
        I1
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: <testLibraryFragment>::@extensionType::I1
      representation: <testLibraryFragment>::@extensionType::I1::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::I1::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::I1::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::I1::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::I1::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::I1::@getter::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2
      typeParameters
        E
      representation: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it#element
      primaryConstructor: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@field::it
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@getter::it#element
      constructors
        new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionType::I2::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            bar @63
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          methods
            bar @63
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
        bar
          reference: <testLibrary>::@extensionType::A::@method::bar
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo1 @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
            foo2 @66
              reference: <testLibraryFragment>::@extensionType::A::@method::foo2
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo1 @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
          methods
            foo1 @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo1
              element: <testLibraryFragment>::@extensionType::A::@method::foo1#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
            foo2 @66
              reference: <testLibraryFragment>::@extensionType::A::@method::foo2
              element: <testLibraryFragment>::@extensionType::A::@method::foo2#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          methods
            augment foo1 @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo1
              element: <testLibraryFragment>::@extensionType::A::@method::foo1#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@method::foo1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo1
        foo2
          reference: <testLibrary>::@extensionType::A::@method::foo2
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo2
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        augment A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          methods
            augment foo @86
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extensionType::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        augment A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            augment foo @68
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        extension type A @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          methods
            augment foo @86
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @41
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          methods
            augment foo @68
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <testLibrary>::@extensionType::A::@method::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @39
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            bar @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T @32
              element: <not-implemented>
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @39
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <not-implemented>
          methods
            bar @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@method::bar#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
        bar
          reference: <testLibrary>::@extensionType::A::@method::bar
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @39
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo @73
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          typeParameters
            T @32
              element: <not-implemented>
          fields
            it @39
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @39
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T2 @46
              element: <not-implemented>
          methods
            augment foo @73
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@method::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      typeParameters
        T
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <testLibrary>::@extensionType::A::@method::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
            bar @65
              reference: <testLibraryFragment>::@extensionType::A::@method::bar
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @46
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          methods
            augment foo @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
          methods
            foo @49
              reference: <testLibraryFragment>::@extensionType::A::@method::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
            bar @65
              reference: <testLibraryFragment>::@extensionType::A::@method::bar
              element: <testLibraryFragment>::@extensionType::A::@method::bar#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          typeParameters
            T @46
              element: <not-implemented>
          methods
            augment foo @74
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@method::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      methods
        foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::foo
        bar
          reference: <testLibrary>::@extensionType::A::@method::bar
          firstFragment: <testLibraryFragment>::@extensionType::A::@method::bar
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              setter: setter_0
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            set foo1= @48
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              type: int
              id: field_2
              setter: setter_1
          accessors
            set foo2= @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            synthetic foo1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <testLibraryFragment>::@extensionType::A::@field::foo1#element
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo1
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
          setters
            set foo1 @48
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              element: <testLibraryFragment>::@extensionType::A::@setter::foo1#element
              formalParameters
                _ @57
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo1::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2#element
              setter2: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
          setters
            set foo2 @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2#element
              formalParameters
                _ @71
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2::@parameter::_#element
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          type: int
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@field::foo2
          type: int
          setter: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      setters
        set foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo1
          formalParameters
            requiredPositional _
              type: int
        set foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setter::foo2
          formalParameters
            requiredPositional _
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            static foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_0
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment static set foo= @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @85
                  type: int
              returnType: void
              id: setter_1
              variable: <null>
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            hasInitializer foo @55
              reference: <testLibraryFragment>::@extensionType::A::@field::foo
              element: <testLibraryFragment>::@extensionType::A::@field::foo#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::foo
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
            synthetic get foo
              reference: <testLibraryFragment>::@extensionType::A::@getter::foo
              element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          setters
            augment set foo @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo
              element: <testLibraryFragment>::@extensionType::A::@setter::foo#element
              formalParameters
                _ @85
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo::@parameter::_#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        static hasInitializer foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::foo#element
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::foo
      setters
        synthetic static set foo
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        A @30
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_1
              setter: setter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
              id: field_2
              setter: setter_1
          constructors
            @30
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional final hasImplicitType this.it @36
                  type: int
                  field: <testLibraryFragment>::@extensionType::A::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
              id: getter_0
              variable: field_0
            set foo1= @48
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              parameters
                requiredPositional _ @57
                  type: int
              returnType: void
              id: setter_0
              variable: field_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
            set foo2= @69
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo2
              enclosingElement3: <testLibraryFragment>::@extensionType::A
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
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extensionType::A
          accessors
            augment set foo1= @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
              parameters
                requiredPositional _ @79
                  type: int
              returnType: void
              id: setter_2
              variable: <null>
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
          element: <testLibrary>::@extensionType::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          fields
            it @36
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
            synthetic foo1
              reference: <testLibraryFragment>::@extensionType::A::@field::foo1
              element: <testLibraryFragment>::@extensionType::A::@field::foo1#element
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo1
            synthetic foo2
              reference: <testLibraryFragment>::@extensionType::A::@field::foo2
              element: <testLibraryFragment>::@extensionType::A::@field::foo2#element
              setter2: <testLibraryFragment>::@extensionType::A::@setter::foo2
          constructors
            new
              reference: <testLibraryFragment>::@extensionType::A::@constructor::new
              element: <testLibraryFragment>::@extensionType::A::@constructor::new#element
              typeName: A
              typeNameOffset: 30
              formalParameters
                this.it @36
                  element: <testLibraryFragment>::@extensionType::A::@constructor::new::@parameter::it#element
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
          setters
            set foo1 @48
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo1
              element: <testLibraryFragment>::@extensionType::A::@setter::foo1#element
              formalParameters
                _ @57
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo1::@parameter::_#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
            set foo2 @69
              reference: <testLibraryFragment>::@extensionType::A::@setter::foo2
              element: <testLibraryFragment>::@extensionType::A::@setter::foo2#element
              formalParameters
                _ @78
                  element: <testLibraryFragment>::@extensionType::A::@setter::foo2::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      extensionTypes
        extension type A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A
          previousFragment: <testLibraryFragment>::@extensionType::A
          setters
            augment set foo1 @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1
              element: <testLibraryFragment>::@extensionType::A::@setter::foo1#element
              formalParameters
                _ @79
                  element: <testLibrary>::@fragment::package:test/a.dart::@extensionTypeAugmentation::A::@setterAugmentation::foo1::@parameter::_#element
              previousFragment: <testLibraryFragment>::@extensionType::A::@setter::foo1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo1
          type: int
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo1#element
        synthetic foo2
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::foo2
          type: int
          setter: <testLibraryFragment>::@extensionType::A::@setter::foo2#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
      setters
        set foo2
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo2
          formalParameters
            requiredPositional _
              type: int
        set foo1
          firstFragment: <testLibraryFragment>::@extensionType::A::@setter::foo1
          formalParameters
            requiredPositional _
              type: int
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @46
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@extensionType::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          augmented
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
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
          element: <testLibrary>::@extensionType::A
          fields
            it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@class::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          element: <testLibrary>::@class::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      getters
        synthetic get it
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensionTypes
        A @46
          reference: <testLibraryFragment>::@extensionType::A
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::A::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new
          typeErasure: int
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::A
              returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@extensionType::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      extensionTypes
        augment A @45
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          representation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@field::it
          primaryConstructor: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new
          typeErasure: int
          fields
            final it @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@field::it
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getter::it
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
              returnType: int
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
          element: <testLibrary>::@extensionType::A::@def::0
          fields
            it @52
              reference: <testLibraryFragment>::@extensionType::A::@field::it
              element: <testLibraryFragment>::@extensionType::A::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::A::@getter::it
          getters
            synthetic get it
              reference: <testLibraryFragment>::@extensionType::A::@getter::it
              element: <testLibraryFragment>::@extensionType::A::@getter::it#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@class::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensionTypes
        extension type A @45
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
          element: <testLibrary>::@extensionType::A::@def::1
          fields
            it @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@field::it
              element: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@field::it#element
              getter2: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getter::it
          getters
            synthetic get it
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getter::it
              element: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getter::it#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A::@def::0
      firstFragment: <testLibraryFragment>::@extensionType::A
      representation: <testLibraryFragment>::@extensionType::A::@field::it#element
      primaryConstructor: <testLibraryFragment>::@extensionType::A::@constructor::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::A::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::A::@getter::it#element
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::A::@getter::it
    extension type A
      reference: <testLibrary>::@extensionType::A::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A
      representation: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@field::it#element
      primaryConstructor: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@constructorAugmentation::new#element
      typeErasure: int
      fields
        final it
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@field::it
          type: int
          getter: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getter::it#element
      getters
        synthetic get it
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionTypeAugmentation::A::@getter::it
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
