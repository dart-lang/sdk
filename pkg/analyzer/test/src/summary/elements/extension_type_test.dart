// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/expect.dart';
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

abstract class ExtensionTypeElementTest extends ElementsBaseTest {
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 21
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        const isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_factoryHead_named() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  factory named(int it) => A(it);
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 factory isOriginDeclaration named (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::named
              factoryKeywordOffset: 29
              typeName: null
              formalParameters
                #F6 requiredPositional it (nameOffset:47) (firstTokenOffset:43) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        factory isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional it
              firstFragment: #F6
              type: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_factoryHead_unnamed() async {
    var library = await buildLibrary(r'''
extension type A.primary(int it) {
  factory (int it) => A.primary(it);
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary primary (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::primary
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
            #F5 factory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new
              factoryKeywordOffset: 37
              typeName: null
              formalParameters
                #F6 requiredPositional it (nameOffset:50) (firstTokenOffset:46) (offset:50)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::primary
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary primary
          reference: <testLibrary>::@extensionType::A::@constructor::primary
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        factory isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional it
              firstFragment: #F6
              type: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_formalParameters_optionalNamed_this_private() async {
    var library = await buildLibrary(r'''
extension type A(int? _it) {
  A.named({this._it});
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
            #F2 isOriginDeclaringFormalParameter _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this._it (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
            #F5 isOriginDeclaration named (nameOffset:33) (firstTokenOffset:31) (offset:33)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 31
              periodOffset: 32
              formalParameters
                #F6 optionalNamed final this.it (nameOffset:45) (firstTokenOffset:40) (offset:45)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 isOriginVariable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final promotable isOriginDeclaringFormalParameter _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this._it
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::_it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 optionalNamed final hasImplicitType this.it
              firstFragment: #F6
              type: int?
              privateName: _it
              field: <testLibrary>::@extensionType::A::@field::_it
      getters
        isExtensionTypeMember isOriginVariable _it
          reference: <testLibrary>::@extensionType::A::@getter::_it
          firstFragment: #F7
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::_it
''');
  }

  test_constructor_formalParameters_optionalNamed_this_private_noCorrespondingPublic() async {
    var library = await buildLibrary(r'''
extension type A(int? _123) {
  A.named({this._123});
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
            #F2 isOriginDeclaringFormalParameter _123 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_123
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this._123 (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_123
            #F5 isOriginDeclaration named (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 32
              periodOffset: 33
              formalParameters
                #F6 optionalNamed final this._123 (nameOffset:46) (firstTokenOffset:41) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::_123
          getters
            #F7 isOriginVariable _123 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_123
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_123
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final promotable isOriginDeclaringFormalParameter _123
          reference: <testLibrary>::@extensionType::A::@field::_123
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_123
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_123
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this._123
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::_123
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 optionalNamed final hasImplicitType this._123
              firstFragment: #F6
              type: int?
              field: <testLibrary>::@extensionType::A::@field::_123
      getters
        isExtensionTypeMember isOriginVariable _123
          reference: <testLibrary>::@extensionType::A::@getter::_123
          firstFragment: #F7
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::_123
''');
  }

  test_constructor_formalParameters_requiredNamed_this_private() async {
    var library = await buildLibrary(r'''
extension type A(int? _it) {
  A.named({required this._it});
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
            #F2 isOriginDeclaringFormalParameter _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this._it (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
            #F5 isOriginDeclaration named (nameOffset:33) (firstTokenOffset:31) (offset:33)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 31
              periodOffset: 32
              formalParameters
                #F6 requiredNamed final this.it (nameOffset:54) (firstTokenOffset:40) (offset:54)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 isOriginVariable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final promotable isOriginDeclaringFormalParameter _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this._it
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::_it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredNamed final hasImplicitType this.it
              firstFragment: #F6
              type: int?
              privateName: _it
              field: <testLibrary>::@extensionType::A::@field::_it
      getters
        isExtensionTypeMember isOriginVariable _it
          reference: <testLibrary>::@extensionType::A::@getter::_it
          firstFragment: #F7
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::_it
''');
  }

  test_constructor_newHead_named() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  new named(this.it);
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 isOriginDeclaration named (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@constructor::named
              newKeywordOffset: 29
              typeName: null
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:44) (firstTokenOffset:39) (offset:44)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final hasImplicitType this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_newHead_named_const() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  const new named(this.it);
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 const isOriginDeclaration named (nameOffset:39) (firstTokenOffset:29) (offset:39)
              element: <testLibrary>::@extensionType::A::@constructor::named
              newKeywordOffset: 35
              typeName: null
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:50) (firstTokenOffset:45) (offset:50)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        const isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final hasImplicitType this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_newHead_unnamed() async {
    var library = await buildLibrary(r'''
extension type A.primary(int it) {
  new (this.it);
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary primary (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::primary
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
            #F5 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new
              newKeywordOffset: 37
              typeName: null
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:47) (firstTokenOffset:42) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::primary
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary primary
          reference: <testLibrary>::@extensionType::A::@constructor::primary
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final hasImplicitType this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_newHead_unnamed_const() async {
    var library = await buildLibrary(r'''
extension type A.primary(int it) {
  const new (this.it);
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary primary (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::primary
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new
              newKeywordOffset: 43
              typeName: null
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:53) (firstTokenOffset:48) (offset:53)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::primary
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::primary::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary primary
          reference: <testLibrary>::@extensionType::A::@constructor::primary
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        const isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final hasImplicitType this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_typeName_factory_named() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  factory A.named(int it) => A(it);
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 factory isOriginDeclaration named (nameOffset:39) (firstTokenOffset:29) (offset:39)
              element: <testLibrary>::@extensionType::A::@constructor::named
              factoryKeywordOffset: 29
              typeName: A
              typeNameOffset: 37
              periodOffset: 38
              formalParameters
                #F6 requiredPositional it (nameOffset:49) (firstTokenOffset:45) (offset:49)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        factory isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional it
              firstFragment: #F6
              type: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_typeName_factory_unnamed() async {
    var library = await buildLibrary(r'''
extension type A(int it) {
  factory A(int it) => A(it);
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new::@def::0
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@def::0::@formalParameter::it
            #F5 factory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new::@def::1
              factoryKeywordOffset: 29
              typeName: A
              typeNameOffset: 37
              formalParameters
                #F6 requiredPositional it (nameOffset:43) (firstTokenOffset:39) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@def::1::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new::@def::0
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@def::0::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new::@def::0
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        factory isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new::@def::1
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional it
              firstFragment: #F6
              type: int
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_typeName_named_fieldFormalParameter() async {
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 isOriginDeclaration named (nameOffset:31) (firstTokenOffset:29) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 29
              periodOffset: 30
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:42) (firstTokenOffset:37) (offset:42)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: num
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final hasImplicitType this.it
              firstFragment: #F6
              type: num
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_typeName_named_fieldFormalParameter_typed() async {
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 isOriginDeclaration named (nameOffset:31) (firstTokenOffset:29) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 29
              periodOffset: 30
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:46) (firstTokenOffset:37) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: num
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional final this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: num
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_constructor_typeName_named_fieldInitializer() async {
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            #F5 const isOriginDeclaration named (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 35
              periodOffset: 36
              formalParameters
                #F6 requiredPositional a (nameOffset:47) (firstTokenOffset:43) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::a
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: num
              field: <testLibrary>::@extensionType::A::@field::it
        const isExtensionTypeMember isOriginDeclaration named
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
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F7
          returnType: num
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 24
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:30) (firstTokenOffset:26) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@extensionType::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @52
                  staticType: int
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static const hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@extensionType::A::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @48
                  staticType: int
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static const hasImplicitType hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: <testLibrary>::@extensionType::A::@field::foo
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        final hasImplicitType hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F5 isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration foo
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@extensionType::X::@field::it
          getters
            #F6 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F5
          type: C
          getter: <testLibrary>::@extensionType::X::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::X::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:56) (firstTokenOffset:41) (offset:56)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:43) (firstTokenOffset:28) (offset:43)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: num
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: num
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::X::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::X::@getter::it
  extensionTypes
    extension type X
      reference: <testLibrary>::@extensionType::X
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::X::@field::it
      primaryConstructor: <testLibrary>::@extensionType::X::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::X::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::X::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@extensionType::X::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::X::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::X::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::X::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final promotable isOriginDeclaringFormalParameter _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::_it
  fieldNameNonPromotabilityInfo
    _it
      conflictingFields
        <testLibrary>::@class::B::@field::_it
      conflictingGetters
        <testLibrary>::@class::C::@getter::_it
''');
  }

  test_lazy_all_constructors() async {
    var library = await buildLibrary('''
extension type E.foo(int _) {}
''');

    var constructors = library.getExtensionType('E')!.constructors;
    expect(constructors, hasLength(1));
  }

  test_lazy_all_fields() async {
    var library = await buildLibrary('''
extension type E(int _) {
  static int foo = 42;
}
''');

    var fields = library.getExtensionType('E')!.fields;
    expect(fields, hasLength(2));
  }

  test_lazy_all_getters() async {
    var library = await buildLibrary('''
extension type E(int _) {
  int get foo => 0;
}
''');

    var getters = library.getExtensionType('E')!.getters;
    expect(getters, hasLength(2));
  }

  test_lazy_all_methods() async {
    var library = await buildLibrary('''
extension type E(int _) {
  void foo() {}
}
''');

    var methods = library.getExtensionType('E')!.methods;
    expect(methods, hasLength(1));
  }

  test_lazy_all_setters() async {
    var library = await buildLibrary('''
extension type E(int _) {
  set foo(int _) {}
}
''');

    var setters = library.getExtensionType('E')!.setters;
    expect(setters, hasLength(1));
  }

  test_lazy_byReference_constructor() async {
    var library = await buildLibrary('''
extension type E.foo(int _) {}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var foo = getElementOfReference(E, ['@constructor', 'foo']);
    expect(foo.name, 'foo');
  }

  test_lazy_byReference_field() async {
    var library = await buildLibrary('''
extension type E(int _) {
  static int bar = 42;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var bar = getElementOfReference(E, ['@field', 'bar']);
    expect(bar.name, 'bar');
  }

  test_lazy_byReference_getter() async {
    var library = await buildLibrary('''
extension type E(int _) {
  int get foo => 0;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var foo = getElementOfReference(E, ['@getter', 'foo']);
    expect(foo.name, 'foo');
  }

  test_lazy_byReference_method() async {
    var library = await buildLibrary('''
extension type E(int _) {
  void foo() {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var foo = getElementOfReference(E, ['@method', 'foo']);
    expect(foo.name, 'foo');
  }

  test_lazy_byReference_setter() async {
    var library = await buildLibrary('''
extension type E(int _) {
  set foo(int _) {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtensionType('E')!;
    var foo = getElementOfReference(E, ['@setter', 'foo']);
    expect(foo.name, 'foo');
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 37
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:43) (firstTokenOffset:39) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F4 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              formalParameters
                #F5 requiredPositional a (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@method::foo::@formalParameter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F4 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              formalParameters
                #F5 optionalNamed a (nameOffset:43) (firstTokenOffset:39) (offset:43)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F4
          formalParameters
            #E0 optionalNamed hasDefaultValue a
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@extensionType::0::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@extensionType::0::@getter::it
  extensionTypes
    extension type <null-name>
      reference: <testLibrary>::@extensionType::0
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::0::@field::it
      primaryConstructor: <testLibrary>::@extensionType::0::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::0::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::0::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::0::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::0::@getter::it
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extensionType::0::@field::it
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_defaultValue_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({int a = 0}) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 14
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalNamed final this.a (nameOffset:22) (firstTokenOffset:18) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @26
                      staticType: int
          getters
            #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final hasDefaultValue declaring this.a
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::a
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_defaultValue_optionalPositional() async {
    var library = await buildLibrary(r'''
extension type A([int a = 0]) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 14
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalPositional final this.a (nameOffset:22) (firstTokenOffset:18) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @26
                      staticType: int
          getters
            #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasDefaultValue declaring this.a
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::a
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_documentationComment() async {
    var library = await buildLibrary(r'''
extension type A(
  /// first
  /// second
  int it,
) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:49) (firstTokenOffset:20) (offset:49)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  documentationComment: /// first\n/// second
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          documentationComment: /// first\n/// second
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              documentationComment: /// first\n/// second
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_fieldFormalParameter() async {
    var library = await buildLibrary(r'''
extension type A(this.it) {}
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
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 10
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType this.it
              firstFragment: #F4
              type: dynamic
              field: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_formalParameters_fieldFormalParameter_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(this.it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 10
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:38) (firstTokenOffset:33) (offset:38)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType this.it
              firstFragment: #F4
              type: dynamic
              field: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_formalParameters_fieldFormalParameter_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({this.it = 0}) {}
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
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalNamed final this.it (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @28
                      staticType: int
          getters
            #F5 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final hasDefaultValue hasImplicitType this.it
              firstFragment: #F4
              type: dynamic
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_formalParameters_functionTypedFormalParameter() async {
    var library = await buildLibrary(r'''
extension type A(int it()) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 11
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int Function()
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int Function()
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int Function()
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int Function()
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_functionTypedFormalParameter_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int it()) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 11
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int Function()
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int Function()
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int Function()
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int Function()
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_const() async {
    var library = await buildLibrary(r'''
extension type A(const int it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 15
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:27) (firstTokenOffset:17) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_const_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(const int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 15
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:43) (firstTokenOffset:33) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant() async {
    var library = await buildLibrary(r'''
extension type A(covariant int it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 19
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional covariant final this.it (nameOffset:31) (firstTokenOffset:17) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional covariant final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(covariant int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 19
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional covariant final this.it (nameOffset:47) (firstTokenOffset:33) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional covariant final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_hasType() async {
    var library = await buildLibrary(r'''
extension type A(final int it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 15
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:27) (firstTokenOffset:17) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_hasType_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(final int it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 15
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:43) (firstTokenOffset:33) (offset:43)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_noType() async {
    var library = await buildLibrary(r'''
extension type A(final it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 11
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:23) (firstTokenOffset:17) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.it
              firstFragment: #F4
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_noType_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(final it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 11
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:39) (firstTokenOffset:33) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.it
              firstFragment: #F4
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_required() async {
    var library = await buildLibrary(r'''
extension type A(required int it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 18
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:30) (firstTokenOffset:17) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_static() async {
    var library = await buildLibrary(r'''
extension type A(static int it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 16
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:28) (firstTokenOffset:24) (offset:28)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_var() async {
    var library = await buildLibrary(r'''
extension type A(var it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 9
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.it
              firstFragment: #F4
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_keyword_var_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(var it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 9
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.it
              firstFragment: #F4
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({int? it}) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 12
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalNamed final this.it (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final declaring this.it
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A({int? it}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 12
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 optionalNamed final this.it (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final declaring this.it
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({int? a, int? b}) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 19
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalNamed final this.a (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalNamed b (nameOffset:31) (firstTokenOffset:26) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final declaring this.a
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_optionalNamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A({int? a, int? b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 19
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 optionalNamed final this.a (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalNamed b (nameOffset:47) (firstTokenOffset:42) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final declaring this.a
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_requiredNamed() async {
    var library = await buildLibrary(r'''
extension type A({int? a, required int b}) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 27
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalNamed final this.a (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 requiredNamed b (nameOffset:39) (firstTokenOffset:26) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final declaring this.a
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 requiredNamed b
              firstFragment: #F5
              type: int
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_type_fromDefaultValue() async {
    var library = await buildLibrary(r'''
extension type A({it = 0}) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalNamed final this.it (nameOffset:18) (firstTokenOffset:18) (offset:18)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @23
                      staticType: int
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final hasDefaultValue hasImplicitType declaring this.it
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional() async {
    var library = await buildLibrary(r'''
extension type A([int? it]) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 12
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalPositional final this.it (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final declaring this.it
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A([int? it]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 12
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 optionalPositional final this.it (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final declaring this.it
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_optionalPositional() async {
    var library = await buildLibrary(r'''
extension type A([int? a, int? b]) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 19
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalPositional final this.a (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalPositional b (nameOffset:31) (firstTokenOffset:26) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final declaring this.a
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalPositional b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_optionalPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A([int? a, int? b]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 19
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 optionalPositional final this.a (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalPositional b (nameOffset:47) (firstTokenOffset:42) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final declaring this.a
              firstFragment: #F4
              type: int?
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalPositional b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_type_fromDefaultValue() async {
    var library = await buildLibrary(r'''
extension type A([it = 0]) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalPositional final this.it (nameOffset:18) (firstTokenOffset:18) (offset:18)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @23
                      staticType: int
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasDefaultValue hasImplicitType declaring this.it
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_type_fromDefaultValue_chain() async {
    var library = await buildLibrary(r'''
extension type A([it = 0]) {}
extension type B(A it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalPositional final this.it (nameOffset:18) (firstTokenOffset:18) (offset:18)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @23
                      staticType: int
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F6 extension type B (nameOffset:45) (firstTokenOffset:30) (offset:45)
          element: <testLibrary>::@extensionType::B
          fields
            #F7 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::B::@field::it
          constructors
            #F8 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:45) (offset:45)
              element: <testLibrary>::@extensionType::B::@constructor::new
              typeName: B
              typeNameOffset: 45
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:49) (firstTokenOffset:47) (offset:49)
                  element: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasDefaultValue hasImplicitType declaring this.it
              firstFragment: #F4
              type: int
              constantInitializer
                fragment: #F4
                expression: expression_0
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F7
          type: A
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::B::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional final declaring this.it
              firstFragment: #F9
              type: A
              field: <testLibrary>::@extensionType::B::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed() async {
    var library = await buildLibrary(r'''
extension type A({required int it}) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 20
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredNamed final this.it (nameOffset:31) (firstTokenOffset:18) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredNamed final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A({required int it}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 20
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredNamed final this.it (nameOffset:47) (firstTokenOffset:34) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredNamed final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({required int a, int? b}) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 27
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredNamed final this.a (nameOffset:31) (firstTokenOffset:18) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalNamed b (nameOffset:39) (firstTokenOffset:34) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredNamed final declaring this.a
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_requiredNamed() async {
    var library = await buildLibrary(r'''
extension type A({required int a, required int b}) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 35
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredNamed final this.a (nameOffset:31) (firstTokenOffset:18) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 requiredNamed b (nameOffset:47) (firstTokenOffset:34) (offset:47)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredNamed final declaring this.a
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 requiredNamed b
              firstFragment: #F5
              type: int
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional() async {
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 9
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
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
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 9
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A(int a, {int? b}) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 18
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.a (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalNamed b (nameOffset:30) (firstTokenOffset:25) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.a
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalNamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int a, {int? b}) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 18
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.a (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalNamed b (nameOffset:46) (firstTokenOffset:41) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.a
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalNamed b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalPositional() async {
    var library = await buildLibrary(r'''
extension type A(int a, [int? b]) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 18
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.a (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalPositional b (nameOffset:30) (firstTokenOffset:25) (offset:30)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.a
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalPositional b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int a, [int? b]) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 18
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.a (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 optionalPositional b (nameOffset:46) (firstTokenOffset:41) (offset:46)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.a
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 optionalPositional b
              firstFragment: #F5
              type: int?
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_requiredPositional() async {
    var library = await buildLibrary(r'''
extension type A(int a, int b) {}
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
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 15
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.a (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 requiredPositional b (nameOffset:28) (firstTokenOffset:24) (offset:28)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.a
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 requiredPositional b
              firstFragment: #F5
              type: int
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_requiredPositional_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int a, int b) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::a
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 15
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.a (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
                #F5 requiredPositional b (nameOffset:44) (firstTokenOffset:40) (offset:44)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::b
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::a
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::a
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter a
          reference: <testLibrary>::@extensionType::A::@field::a
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::a
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::a
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.a
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::a
            #E1 requiredPositional b
              firstFragment: #F5
              type: int
      getters
        isExtensionTypeMember isOriginVariable a
          reference: <testLibrary>::@extensionType::A::@getter::a
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::a
''');
  }

  test_primaryConstructor_formalParameters_memberWithClassName() async {
    var library = await buildLibrary(r'''
extension type A(int A) {}
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
            #F2 isOriginDeclaringFormalParameter A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::A
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 8
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.A (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::A
          getters
            #F5 isOriginVariable A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::A
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::A
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter A
          reference: <testLibrary>::@extensionType::A::@field::A
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::A
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::A
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.A
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::A
      getters
        isExtensionTypeMember isOriginVariable A
          reference: <testLibrary>::@extensionType::A::@getter::A
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::A
''');
  }

  test_primaryConstructor_formalParameters_memberWithClassName_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int A) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::A
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 8
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.A (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::A
          getters
            #F5 isOriginVariable A (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::A
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::A
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter A
          reference: <testLibrary>::@extensionType::A::@field::A
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::A
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::A
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.A
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::A
      getters
        isExtensionTypeMember isOriginVariable A
          reference: <testLibrary>::@extensionType::A::@getter::A
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::A
''');
  }

  test_primaryConstructor_formalParameters_metadata() async {
    var library = await buildLibrary(r'''
extension type A(@deprecated int it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 21
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:33) (firstTokenOffset:17) (offset:33)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  metadata
                    Annotation
                      atSign: @ @17
                      name: SimpleIdentifier
                        token: deprecated @18
                        element: dart:core::@getter::deprecated
                        staticType: null
                      element: dart:core::@getter::deprecated
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: deprecated @18
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              metadata
                Annotation
                  atSign: @ @17
                  name: SimpleIdentifier
                    token: deprecated @18
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_noFormalParameters() async {
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
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 3
              typeName: A
              typeNameOffset: 15
          getters
            #F4 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F4
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_formalParameters_noFormalParameters_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
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
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 3
              typeName: A
              typeNameOffset: 31
          getters
            #F4 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F4
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation() async {
    var library = await buildLibrary(r'''
extension type A(it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 5
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:17) (firstTokenOffset:17) (offset:17)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.it
              firstFragment: #F4
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 5
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:33) (firstTokenOffset:33) (offset:33)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.it
              firstFragment: #F4
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_withMetadata() async {
    var library = await buildLibrary(r'''
extension type A(@deprecated it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 17
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:29) (firstTokenOffset:17) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  metadata
                    Annotation
                      atSign: @ @17
                      name: SimpleIdentifier
                        token: deprecated @18
                        element: dart:core::@getter::deprecated
                        staticType: null
                      element: dart:core::@getter::deprecated
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @17
              name: SimpleIdentifier
                token: deprecated @18
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.it
              firstFragment: #F4
              type: Object?
              metadata
                Annotation
                  atSign: @ @17
                  name: SimpleIdentifier
                    token: deprecated @18
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_withMetadata_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(@deprecated it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 17
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:45) (firstTokenOffset:33) (offset:45)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  metadata
                    Annotation
                      atSign: @ @33
                      name: SimpleIdentifier
                        token: deprecated @34
                        element: dart:core::@getter::deprecated
                        staticType: null
                      element: dart:core::@getter::deprecated
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final hasImplicitType isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @33
              name: SimpleIdentifier
                token: deprecated @34
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.it
              firstFragment: #F4
              type: Object?
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: deprecated @34
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_optionalNamed_private() async {
    var library = await buildLibrary(r'''
extension type A({int? _it}) {}
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
            #F2 isOriginDeclaringFormalParameter _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalNamed final this.it (nameOffset:23) (firstTokenOffset:18) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int?
      fields
        final promotable isOriginDeclaringFormalParameter _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F2
          type: int?
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final declaring this.it
              firstFragment: #F4
              type: int?
              privateName: _it
              field: <testLibrary>::@extensionType::A::@field::_it
      getters
        isExtensionTypeMember isOriginVariable _it
          reference: <testLibrary>::@extensionType::A::@getter::_it
          firstFragment: #F5
          returnType: int?
          variable: <testLibrary>::@extensionType::A::@field::_it
''');
  }

  test_primaryConstructor_formalParameters_requiredNamed_private() async {
    var library = await buildLibrary(r'''
extension type A({required int _it}) {}
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
            #F2 isOriginDeclaringFormalParameter _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::_it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredNamed final this.it (nameOffset:31) (firstTokenOffset:18) (offset:31)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable _it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::_it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::_it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final promotable isOriginDeclaringFormalParameter _it
          reference: <testLibrary>::@extensionType::A::@field::_it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::_it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredNamed final declaring this.it
              firstFragment: #F4
              type: int
              privateName: _it
              field: <testLibrary>::@extensionType::A::@field::_it
      getters
        isExtensionTypeMember isOriginVariable _it
          reference: <testLibrary>::@extensionType::A::@getter::_it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::_it
''');
  }

  test_primaryConstructor_formalParameters_superFormalParameter() async {
    var library = await buildLibrary(r'''
extension type A(super.it) {}
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
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 11
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final super.it (nameOffset:23) (firstTokenOffset:17) (offset:23)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType super.it
              firstFragment: #F4
              type: dynamic
              superConstructorParameter: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_formalParameters_superFormalParameter_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(super.it) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 11
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final super.it (nameOffset:39) (firstTokenOffset:33) (offset:39)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType super.it
              firstFragment: #F4
              type: dynamic
              superConstructorParameter: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_formalParameters_superFormalParameter_optionalNamed() async {
    var library = await buildLibrary(r'''
extension type A({super.it = 0}) {}
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
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 optionalNamed final super.it (nameOffset:24) (firstTokenOffset:18) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  initializer: expression_0
                    IntegerLiteral
                      literal: 0 @29
                      staticType: int
          getters
            #F5 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed final hasDefaultValue hasImplicitType super.it
              firstFragment: #F4
              type: dynamic
              constantInitializer
                fragment: #F4
                expression: expression_0
              superConstructorParameter: <null>
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_formalParameters_trailingComma() async {
    var library = await buildLibrary(r'''
extension type A(int it,) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 10
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_formalParameters_trailingComma_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
extension type A(int it,) {}
''');

    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type A (nameOffset:31) (firstTokenOffset:16) (offset:31)
          element: <testLibrary>::@extensionType::A
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 31
              codeLength: 10
              typeName: A
              typeNameOffset: 31
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:37) (firstTokenOffset:33) (offset:37)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_missing() async {
    var library = await buildLibrary(r'''
extension type A {}
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
            #F2 isOriginExtensionTypeRecoveryRepresentation <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::0
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              codeOffset: 15
              codeLength: 2
              typeName: A
              typeNameOffset: 15
          getters
            #F4 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::1
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::0
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginExtensionTypeRecoveryRepresentation <null-name>
          reference: <testLibrary>::@extensionType::A::@field::0
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::1
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
      getters
        isExtensionTypeMember isOriginVariable <null-name>
          reference: <testLibrary>::@extensionType::A::@getter::1
          firstFragment: #F4
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::0
''');
  }

  test_primaryConstructor_named() async {
    var library = await buildLibrary(r'''
extension type A.name(int it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary name (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::name
              codeOffset: 15
              codeLength: 14
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:26) (firstTokenOffset:22) (offset:26)
                  element: <testLibrary>::@extensionType::A::@constructor::name::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::name
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::name::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary name
          reference: <testLibrary>::@extensionType::A::@constructor::name
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_primaryConstructor_scopes() async {
    var library = await buildLibrary('''
const foo = 0;
extension type E<@foo T>([@foo int it = foo]) {
  static const foo = 1;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:30) (firstTokenOffset:15) (offset:30)
          element: <testLibrary>::@extensionType::E
          typeParameters
            #F2 T (nameOffset:37) (firstTokenOffset:32) (offset:37)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          fields
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@extensionType::E::@field::it
            #F4 hasInitializer isOriginDeclaration foo (nameOffset:78) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::E::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @84
                  staticType: int
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:30) (offset:30)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 30
              formalParameters
                #F6 optionalPositional final this.it (nameOffset:50) (firstTokenOffset:41) (offset:50)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
                  metadata
                    Annotation
                      atSign: @ @41
                      name: SimpleIdentifier
                        token: foo @42
                        element: <testLibrary>::@extensionType::E::@getter::foo
                        staticType: null
                      element: <testLibrary>::@extensionType::E::@getter::foo
                  initializer: expression_1
                    SimpleIdentifier
                      token: foo @55
                      element: <testLibrary>::@extensionType::E::@getter::foo
                      staticType: int
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@extensionType::E::@getter::it
            #F8 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::E::@getter::foo
      topLevelVariables
        #F9 hasInitializer isOriginDeclaration foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_2
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  extensionTypes
    extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: foo @33
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F3
          metadata
            Annotation
              atSign: @ @41
              name: SimpleIdentifier
                token: foo @42
                element: <testLibrary>::@extensionType::E::@getter::foo
                staticType: null
              element: <testLibrary>::@extensionType::E::@getter::foo
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
        static const hasImplicitType hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::E::@field::foo
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@extensionType::E::@getter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 optionalPositional final hasDefaultValue declaring this.it
              firstFragment: #F6
              type: int
              metadata
                Annotation
                  atSign: @ @41
                  name: SimpleIdentifier
                    token: foo @42
                    element: <testLibrary>::@extensionType::E::@getter::foo
                    staticType: null
                  element: <testLibrary>::@extensionType::E::@getter::foo
              constantInitializer
                fragment: #F6
                expression: expression_1
              field: <testLibrary>::@extensionType::E::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::E::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::foo
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F9
      type: int
      constantInitializer
        fragment: #F9
        expression: expression_2
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_primaryConstructor_typeParameters() async {
    var library = await buildLibrary(r'''
extension type E<T extends U, U extends num>(T it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::E
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
            #F3 U (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E1 U
          fields
            #F4 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@field::it
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:47) (firstTokenOffset:45) (offset:47)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@getter::it
  extensionTypes
    notSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: U
        #E1 U
          firstFragment: #F3
          bound: num
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: T
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional final declaring this.it
              firstFragment: #F6
              type: T
              field: <testLibrary>::@extensionType::E::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_primaryConstructorBody_constantInitializers_assertInitializer() async {
    var library = await buildLibrary(r'''
extension type const E(int it) {
  this : assert(it > 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@field::it
          constructors
            #F3 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 21
              thisKeywordOffset: 35
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@getter::it
  extensionTypes
    extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        const isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
          constantInitializers
            AssertInitializer
              assertKeyword: assert @42
              leftParenthesis: ( @48
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: it @49
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
                  staticType: int
                operator: > @52
                rightOperand: IntegerLiteral
                  literal: 0 @54
                  staticType: int
                element: dart:core::@class::num::@method::>
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @55
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_primaryConstructorBody_duplicate() async {
    var library = await buildLibrary(r'''
extension type const E(int it) {
  @Deprecated('0')
  this : assert(it >= 0);
  @Deprecated('1')
  this : assert(it >= 1);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@field::it
          constructors
            #F3 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@extensionType::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @35
                  name: SimpleIdentifier
                    token: Deprecated @36
                    element: dart:core::@class::Deprecated
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @46
                    arguments
                      SimpleStringLiteral
                        literal: '0' @47
                    rightParenthesis: ) @50
                  element: dart:core::@class::Deprecated::@constructor::new
              typeName: E
              typeNameOffset: 21
              thisKeywordOffset: 54
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@getter::it
  extensionTypes
    extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        const isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F3
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: Deprecated @36
                element: dart:core::@class::Deprecated
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @46
                arguments
                  SimpleStringLiteral
                    literal: '0' @47
                rightParenthesis: ) @50
              element: dart:core::@class::Deprecated::@constructor::new
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
          constantInitializers
            AssertInitializer
              assertKeyword: assert @61
              leftParenthesis: ( @67
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: it @68
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
                  staticType: int
                operator: >= @71
                rightOperand: IntegerLiteral
                  literal: 0 @74
                  staticType: int
                element: dart:core::@class::num::@method::>=
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @75
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_primaryConstructorBody_metadata() async {
    var library = await buildLibrary(r'''
extension type E(int it) {
  @deprecated
  this;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: deprecated @30
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              typeName: E
              typeNameOffset: 15
              thisKeywordOffset: 43
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@getter::it
  extensionTypes
    extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F3
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: deprecated @30
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_primaryConstructorBody_named() async {
    var library = await buildLibrary(r'''
extension type const E.named(int it) {
  this : assert(it > 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@field::it
          constructors
            #F3 const isOriginDeclaration isPrimary named (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@extensionType::E::@constructor::named
              typeName: E
              typeNameOffset: 21
              periodOffset: 22
              thisKeywordOffset: 41
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:33) (firstTokenOffset:29) (offset:33)
                  element: <testLibrary>::@extensionType::E::@constructor::named::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@getter::it
  extensionTypes
    extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::named
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::named::@formalParameter::it
      constructors
        const isExtensionTypeMember isOriginDeclaration isPrimary named
          reference: <testLibrary>::@extensionType::E::@constructor::named
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
          constantInitializers
            AssertInitializer
              assertKeyword: assert @48
              leftParenthesis: ( @54
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: it @55
                  element: <testLibrary>::@extensionType::E::@constructor::named::@formalParameter::it
                  staticType: int
                operator: > @58
                rightOperand: IntegerLiteral
                  literal: 0 @60
                  staticType: int
                element: dart:core::@class::num::@method::>
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @61
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
''');
  }

  test_primaryConstructorBody_primaryInitializerScope() async {
    var library = await buildLibrary(r'''
extension type const E(int it) {
  this : assert(it > 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E (nameOffset:21) (firstTokenOffset:0) (offset:21)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@field::it
          constructors
            #F3 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 21
              thisKeywordOffset: 35
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@extensionType::E::@getter::it
  extensionTypes
    extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        const isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
          constantInitializers
            AssertInitializer
              assertKeyword: assert @42
              leftParenthesis: ( @48
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: it @49
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
                  staticType: int
                operator: > @52
                rightOperand: IntegerLiteral
                  literal: 0 @54
                  staticType: int
                element: dart:core::@class::num::@method::>
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @55
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
            #F3 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          setters
            #F5 isOriginDeclaration foo (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F6 requiredPositional _ (nameOffset:44) (firstTokenOffset:37) (offset:44)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F3
          type: double
          setter: <testLibrary>::@extensionType::A::@setter::foo
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember isOriginDeclaration foo
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:19) (firstTokenOffset:17) (offset:19)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F6 extension type B (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@extensionType::B
          fields
            #F7 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::B::@field::it
          constructors
            #F8 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@extensionType::B::@constructor::new
              typeName: B
              typeNameOffset: 42
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:46) (firstTokenOffset:44) (offset:46)
                  element: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    hasRepresentationSelfReference extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: InvalidType
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::A::@field::it
    hasRepresentationSelfReference extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F7
          type: InvalidType
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::B::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional final declaring this.it
              firstFragment: #F9
              type: InvalidType
              field: <testLibrary>::@extensionType::B::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F10
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_typeErasure_hasExtension_cycle2_typeArgument() async {
    var library = await buildLibrary(r'''
extension type A(B it) {}

extension type B(List<B> it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:19) (firstTokenOffset:17) (offset:19)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F6 extension type B (nameOffset:42) (firstTokenOffset:27) (offset:42)
          element: <testLibrary>::@extensionType::B
          fields
            #F7 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::B::@field::it
          constructors
            #F8 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@extensionType::B::@constructor::new
              typeName: B
              typeNameOffset: 42
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:52) (firstTokenOffset:44) (offset:52)
                  element: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: B
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: B
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
          returnType: B
          variable: <testLibrary>::@extensionType::A::@field::it
    hasRepresentationSelfReference extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F7
          type: InvalidType
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::B::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional final declaring this.it
              firstFragment: #F9
              type: InvalidType
              field: <testLibrary>::@extensionType::B::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F10
          returnType: InvalidType
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_typeErasure_hasExtension_cycle_self() async {
    var library = await buildLibrary(r'''
extension type A(A it) {}
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F3 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional final this.it (nameOffset:19) (firstTokenOffset:17) (offset:19)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    hasRepresentationSelfReference extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: InvalidType
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: InvalidType
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F4
              type: InvalidType
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F5
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: A Function(A)
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F5 extension type B (nameOffset:45) (firstTokenOffset:30) (offset:45)
          element: <testLibrary>::@extensionType::B
          fields
            #F6 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F6
          type: A<double>
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F4 extension type B (nameOffset:44) (firstTokenOffset:29) (offset:44)
          element: <testLibrary>::@extensionType::B
          fields
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F6 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@extensionType::B::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F5
          type: List<A>
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F2 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F3 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F4 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:45) (firstTokenOffset:35) (offset:45)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          type: Map<T, U>
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional final declaring this.it
              firstFragment: #F6
              type: Map<T, U>
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:52) (firstTokenOffset:29) (offset:52)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F10
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F11
          constructors
            #F8 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 52
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:58) (firstTokenOffset:54) (offset:58)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F6
                  nextFragment: #F12
              nextFragment: #F13
              previousFragment: #F5
        #F10 extension type A (nameOffset:89) (firstTokenOffset:66) (offset:89)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F11 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:89)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F13 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:89) (offset:89)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 89
              formalParameters
                #F12 requiredPositional final this.it (nameOffset:95) (firstTokenOffset:91) (offset:95)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F8
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
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
            #F3 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 23
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F10 isOriginDeclaration foo1 (nameOffset:42) (firstTokenOffset:37) (offset:42)
              element: <testLibrary>::@extensionType::A::@method::foo1
        #F2 extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F8 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:84) (firstTokenOffset:80) (offset:84)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F6
              previousFragment: #F5
          methods
            #F11 isOriginDeclaration foo2 (nameOffset:97) (firstTokenOffset:92) (offset:97)
              element: <testLibrary>::@extensionType::A::@method::foo2
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: #F10
          returnType: void
        isExtensionTypeMember isOriginDeclaration foo2
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:52) (firstTokenOffset:29) (offset:52)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F8 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 52
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:58) (firstTokenOffset:54) (offset:58)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F6
              previousFragment: #F5
            #F10 isOriginDeclaration named (nameOffset:68) (firstTokenOffset:66) (offset:68)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F10
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:55) (firstTokenOffset:32) (offset:55)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:55) (offset:55)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 55
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:64) (firstTokenOffset:60) (offset:64)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
            #F12 isOriginDeclaration named (nameOffset:74) (firstTokenOffset:72) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 72
              periodOffset: 73
              formalParameters
                #F13 requiredPositional a (nameOffset:82) (firstTokenOffset:80) (offset:82)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F12
          formalParameters
            #E2 requiredPositional a
              firstFragment: #F13
              type: T
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 isOriginDeclaration isPrimary named (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 15
              periodOffset: 16
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F2 extension type A (nameOffset:58) (firstTokenOffset:35) (offset:58)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F8 augment isOriginDeclaration isPrimary named (nameOffset:60) (firstTokenOffset:58) (offset:60)
              element: <testLibrary>::@extensionType::A::@constructor::named
              typeName: A
              typeNameOffset: 58
              periodOffset: 59
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:70) (firstTokenOffset:66) (offset:70)
                  element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
                  previousFragment: #F6
              previousFragment: #F5
            #F10 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary named
          reference: <testLibrary>::@extensionType::A::@constructor::named
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F10
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F12 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F13 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:108) (firstTokenOffset:108) (offset:108)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        static isExtensionTypeMember isOriginVariable foo
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F12 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F13 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F15
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F16
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:108) (firstTokenOffset:108) (offset:108)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
              nextFragment: #F17
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
                  nextFragment: #F18
              nextFragment: #F19
              previousFragment: #F7
        #F15 extension type A (nameOffset:143) (firstTokenOffset:120) (offset:143)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F16 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:143)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
            #F17 augment hasInitializer isOriginDeclaration foo (nameOffset:176) (firstTokenOffset:176) (offset:176)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F6
          constructors
            #F19 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:143) (offset:143)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 143
              formalParameters
                #F18 requiredPositional final this.it (nameOffset:149) (firstTokenOffset:145) (offset:149)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F10
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        static isExtensionTypeMember isOriginVariable foo
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F12 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F13
          setters
            #F14 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F16
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F17
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
                  nextFragment: #F18
              nextFragment: #F19
              previousFragment: #F7
          getters
            #F13 augment isOriginDeclaration foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F12
        #F16 extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F17 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:181) (firstTokenOffset:181) (offset:181)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F19 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:148) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F18 requiredPositional final this.it (nameOffset:154) (firstTokenOffset:150) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F10
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@setter::foo
          firstFragment: #F14
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F15
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F12 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F13 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
              nextFragment: #F15
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F16
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F17
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
                  nextFragment: #F18
              nextFragment: #F19
              previousFragment: #F7
          setters
            #F15 augment isOriginDeclaration foo (nameOffset:108) (firstTokenOffset:89) (offset:108)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F20 requiredPositional _ (nameOffset:116) (firstTokenOffset:112) (offset:116)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
              previousFragment: #F13
        #F16 extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F17 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:181) (firstTokenOffset:181) (offset:181)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F19 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:148) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F18 requiredPositional final this.it (nameOffset:154) (firstTokenOffset:150) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F10
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        static isExtensionTypeMember isOriginVariable foo
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F12 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F13 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:111) (firstTokenOffset:111) (offset:111)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        static isExtensionTypeMember isOriginVariable foo
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F12 isOriginDeclaration foo (nameOffset:44) (firstTokenOffset:29) (offset:44)
              element: <testLibrary>::@extensionType::A::@getter::foo
        #F2 extension type A (nameOffset:80) (firstTokenOffset:57) (offset:80)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:113) (firstTokenOffset:113) (offset:113)
              element: <testLibrary>::@extensionType::A::@field::foo
              previousFragment: #F5
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:80) (offset:80)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 80
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:86) (firstTokenOffset:82) (offset:86)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginGetterSetter foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F12
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo1 (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F6 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 isOriginVariable foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo1
          setters
            #F12 isOriginVariable foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::value
        #F2 extension type A (nameOffset:76) (firstTokenOffset:53) (offset:76)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F14 hasInitializer isOriginDeclaration foo2 (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F9 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:76) (offset:76)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 76
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:82) (firstTokenOffset:78) (offset:82)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
          getters
            #F15 isOriginVariable foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@extensionType::A::@getter::foo2
          setters
            #F16 isOriginVariable foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              formalParameters
                #F17 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::value
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        static hasInitializer isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F14
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        static isExtensionTypeMember isOriginVariable foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo2
      setters
        static isExtensionTypeMember isOriginVariable foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        static isExtensionTypeMember isOriginVariable foo2
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F6 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 isOriginDeclaration foo1 (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo1
        #F2 extension type A (nameOffset:74) (firstTokenOffset:51) (offset:74)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F12 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F9 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:74) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 74
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:80) (firstTokenOffset:76) (offset:80)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
          getters
            #F13 isOriginDeclaration foo2 (nameOffset:96) (firstTokenOffset:88) (offset:96)
              element: <testLibrary>::@extensionType::A::@getter::foo2
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F12
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginDeclaration foo2
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
            #F7 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F8 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F10
              nextFragment: #F11
          getters
            #F12 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F13 isOriginDeclaration foo1 (nameOffset:38) (firstTokenOffset:32) (offset:38)
              element: <testLibrary>::@extensionType::A::@getter::foo1
        #F2 extension type A (nameOffset:70) (firstTokenOffset:47) (offset:70)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:72) (firstTokenOffset:72) (offset:72)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
            #F14 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F11 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:70) (offset:70)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 70
              formalParameters
                #F10 requiredPositional final this.it (nameOffset:79) (firstTokenOffset:75) (offset:79)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F9
              previousFragment: #F8
          getters
            #F15 isOriginDeclaration foo2 (nameOffset:93) (firstTokenOffset:87) (offset:93)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F14
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional final declaring this.it
              firstFragment: #F9
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        abstract isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extensionType::A::@field::foo1
        abstract isExtensionTypeMember isOriginDeclaration foo2
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F6 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F12
          setters
            #F13 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F9 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
          getters
            #F12 augment isOriginDeclaration foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        static isExtensionTypeMember isOriginVariable foo
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F6 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F12
          setters
            #F13 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F15
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F16
          constructors
            #F9 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F17
              nextFragment: #F18
              previousFragment: #F6
          getters
            #F12 augment isOriginDeclaration foo (nameOffset:112) (firstTokenOffset:89) (offset:112)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F11
              nextFragment: #F19
        #F15 extension type A (nameOffset:148) (firstTokenOffset:125) (offset:148)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F16 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F18 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:148) (offset:148)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 148
              formalParameters
                #F17 requiredPositional final this.it (nameOffset:154) (firstTokenOffset:150) (offset:154)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
          getters
            #F19 augment isOriginDeclaration foo (nameOffset:185) (firstTokenOffset:162) (offset:185)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F12
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        static isExtensionTypeMember isOriginVariable foo
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
            #F6 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F12 isOriginDeclaration foo1 (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo1
              nextFragment: #F13
            #F14 isOriginDeclaration foo2 (nameOffset:58) (firstTokenOffset:50) (offset:58)
              element: <testLibrary>::@extensionType::A::@getter::foo2
        #F2 extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:95) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
          getters
            #F13 augment isOriginDeclaration foo1 (nameOffset:125) (firstTokenOffset:109) (offset:125)
              element: <testLibrary>::@extensionType::A::@getter::foo1
              previousFragment: #F12
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@getter::foo1
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@getter::foo2
          firstFragment: #F14
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F6 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:29) (offset:37)
              element: <testLibrary>::@extensionType::A::@getter::foo
              nextFragment: #F12
        #F2 extension type A (nameOffset:73) (firstTokenOffset:50) (offset:73)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F13
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F14
          constructors
            #F9 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:73) (offset:73)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 73
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:79) (firstTokenOffset:75) (offset:79)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
                  nextFragment: #F15
              nextFragment: #F16
              previousFragment: #F6
          getters
            #F12 augment isOriginDeclaration foo (nameOffset:103) (firstTokenOffset:87) (offset:103)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F11
              nextFragment: #F17
        #F13 extension type A (nameOffset:139) (firstTokenOffset:116) (offset:139)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F14 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:139)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F16 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:139) (offset:139)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 139
              formalParameters
                #F15 requiredPositional final this.it (nameOffset:145) (firstTokenOffset:141) (offset:145)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F9
          getters
            #F17 augment isOriginDeclaration foo (nameOffset:169) (firstTokenOffset:153) (offset:169)
              element: <testLibrary>::@extensionType::A::@getter::foo
              previousFragment: #F12
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F6 extension type I1 (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@extensionType::I1
          fields
            #F7 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::I1::@field::it
          getters
            #F8 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::I1::@getter::it
        #F2 extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
        #F9 extension type I2 (nameOffset:137) (firstTokenOffset:122) (offset:137)
          element: <testLibrary>::@extensionType::I2
          fields
            #F10 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:137)
              element: <testLibrary>::@extensionType::I2::@field::it
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:137)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F10 extension type I1 (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@extensionType::I1
          fields
            #F11 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::I1::@field::it
          constructors
            #F12 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 57
              formalParameters
                #F13 requiredPositional final this.it (nameOffset:64) (firstTokenOffset:60) (offset:64)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F14 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@extensionType::I1::@getter::it
        #F2 extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F15
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F16
          constructors
            #F8 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:95) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F6
                  nextFragment: #F17
              nextFragment: #F18
              previousFragment: #F5
        #F19 extension type I2 (nameOffset:137) (firstTokenOffset:122) (offset:137)
          element: <testLibrary>::@extensionType::I2
          fields
            #F20 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:137)
              element: <testLibrary>::@extensionType::I2::@field::it
          constructors
            #F21 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:137) (offset:137)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 137
              formalParameters
                #F22 requiredPositional final this.it (nameOffset:144) (firstTokenOffset:140) (offset:144)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F23 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:137)
              element: <testLibrary>::@extensionType::I2::@getter::it
        #F15 extension type A (nameOffset:175) (firstTokenOffset:152) (offset:175)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F16 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:175)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F18 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:175) (offset:175)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 175
              formalParameters
                #F17 requiredPositional final this.it (nameOffset:181) (firstTokenOffset:177) (offset:181)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F8
        #F24 extension type I3 (nameOffset:217) (firstTokenOffset:202) (offset:217)
          element: <testLibrary>::@extensionType::I3
          fields
            #F25 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:217)
              element: <testLibrary>::@extensionType::I3::@field::it
          constructors
            #F26 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:217) (offset:217)
              element: <testLibrary>::@extensionType::I3::@constructor::new
              typeName: I3
              typeNameOffset: 217
              formalParameters
                #F27 requiredPositional final this.it (nameOffset:224) (firstTokenOffset:220) (offset:224)
                  element: <testLibrary>::@extensionType::I3::@constructor::new::@formalParameter::it
          getters
            #F28 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:217)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F10
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional final declaring this.it
              firstFragment: #F13
              type: int
              field: <testLibrary>::@extensionType::I1::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F14
          returnType: int
          variable: <testLibrary>::@extensionType::I1::@field::it
    extension type I2
      reference: <testLibrary>::@extensionType::I2
      firstFragment: #F19
      representation: <testLibrary>::@extensionType::I2::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I2::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F20
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F21
          formalParameters
            #E2 requiredPositional final declaring this.it
              firstFragment: #F22
              type: int
              field: <testLibrary>::@extensionType::I2::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I2::@getter::it
          firstFragment: #F23
          returnType: int
          variable: <testLibrary>::@extensionType::I2::@field::it
    extension type I3
      reference: <testLibrary>::@extensionType::I3
      firstFragment: #F24
      representation: <testLibrary>::@extensionType::I3::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I3::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I3::@field::it
          firstFragment: #F25
          type: int
          getter: <testLibrary>::@extensionType::I3::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I3::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I3::@constructor::new
          firstFragment: #F26
          formalParameters
            #E3 requiredPositional final declaring this.it
              firstFragment: #F27
              type: int
              field: <testLibrary>::@extensionType::I3::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F12 extension type I1 (nameOffset:60) (firstTokenOffset:45) (offset:60)
          element: <testLibrary>::@extensionType::I1
          fields
            #F13 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@extensionType::I1::@field::it
          constructors
            #F14 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:60) (offset:60)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 60
              formalParameters
                #F15 requiredPositional final this.it (nameOffset:67) (firstTokenOffset:63) (offset:67)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F16 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@extensionType::I1::@getter::it
        #F2 extension type A (nameOffset:98) (firstTokenOffset:75) (offset:98)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:98) (offset:98)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 98
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:107) (firstTokenOffset:103) (offset:107)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
        #F17 extension type I2 (nameOffset:146) (firstTokenOffset:131) (offset:146)
          element: <testLibrary>::@extensionType::I2
          typeParameters
            #F18 E (nameOffset:149) (firstTokenOffset:149) (offset:149)
              element: #E1 E
          fields
            #F19 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:146)
              element: <testLibrary>::@extensionType::I2::@field::it
          constructors
            #F20 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:146) (offset:146)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 146
              formalParameters
                #F21 requiredPositional final this.it (nameOffset:156) (firstTokenOffset:152) (offset:156)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F22 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:146)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E2 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F12
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F13
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F14
          formalParameters
            #E3 requiredPositional final declaring this.it
              firstFragment: #F15
              type: int
              field: <testLibrary>::@extensionType::I1::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F16
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F20
          formalParameters
            #E4 requiredPositional final declaring this.it
              firstFragment: #F21
              type: int
              field: <testLibrary>::@extensionType::I2::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
        #F12 extension type I1 (nameOffset:60) (firstTokenOffset:45) (offset:60)
          element: <testLibrary>::@extensionType::I1
          fields
            #F13 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@extensionType::I1::@field::it
          constructors
            #F14 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:60) (offset:60)
              element: <testLibrary>::@extensionType::I1::@constructor::new
              typeName: I1
              typeNameOffset: 60
              formalParameters
                #F15 requiredPositional final this.it (nameOffset:67) (firstTokenOffset:63) (offset:67)
                  element: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
          getters
            #F16 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@extensionType::I1::@getter::it
        #F2 extension type A (nameOffset:98) (firstTokenOffset:75) (offset:98)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:98) (offset:98)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 98
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:110) (firstTokenOffset:106) (offset:110)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
        #F17 extension type I2 (nameOffset:149) (firstTokenOffset:134) (offset:149)
          element: <testLibrary>::@extensionType::I2
          typeParameters
            #F18 E (nameOffset:152) (firstTokenOffset:152) (offset:152)
              element: #E1 E
          fields
            #F19 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
              element: <testLibrary>::@extensionType::I2::@field::it
          constructors
            #F20 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:149) (offset:149)
              element: <testLibrary>::@extensionType::I2::@constructor::new
              typeName: I2
              typeNameOffset: 149
              formalParameters
                #F21 requiredPositional final this.it (nameOffset:159) (firstTokenOffset:155) (offset:159)
                  element: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
          getters
            #F22 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:149)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E2 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
    extension type I1
      reference: <testLibrary>::@extensionType::I1
      firstFragment: #F12
      representation: <testLibrary>::@extensionType::I1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::I1::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I1::@field::it
          firstFragment: #F13
          type: int
          getter: <testLibrary>::@extensionType::I1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I1::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I1::@constructor::new
          firstFragment: #F14
          formalParameters
            #E3 requiredPositional final declaring this.it
              firstFragment: #F15
              type: int
              field: <testLibrary>::@extensionType::I1::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::I1::@getter::it
          firstFragment: #F16
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::I2::@field::it
          firstFragment: #F19
          type: int
          getter: <testLibrary>::@extensionType::I2::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::I2::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::I2::@constructor::new
          firstFragment: #F20
          formalParameters
            #E4 requiredPositional final declaring this.it
              firstFragment: #F21
              type: int
              field: <testLibrary>::@extensionType::I2::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F10 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
        #F2 extension type A (nameOffset:69) (firstTokenOffset:46) (offset:69)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F8 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:69) (offset:69)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 69
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:75) (firstTokenOffset:71) (offset:75)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F6
              previousFragment: #F5
          methods
            #F11 isOriginDeclaration bar (nameOffset:88) (firstTokenOffset:83) (offset:88)
              element: <testLibrary>::@extensionType::A::@method::bar
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F10
          returnType: void
        isExtensionTypeMember isOriginDeclaration bar
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F10 isOriginDeclaration foo1 (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo1
              nextFragment: #F11
            #F12 isOriginDeclaration foo2 (nameOffset:51) (firstTokenOffset:46) (offset:51)
              element: <testLibrary>::@extensionType::A::@method::foo2
        #F2 extension type A (nameOffset:87) (firstTokenOffset:64) (offset:87)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:87)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F8 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:87) (offset:87)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 87
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:93) (firstTokenOffset:89) (offset:93)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F6
              previousFragment: #F5
          methods
            #F11 augment isOriginDeclaration foo1 (nameOffset:114) (firstTokenOffset:101) (offset:114)
              element: <testLibrary>::@extensionType::A::@method::foo1
              previousFragment: #F10
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@method::foo1
          firstFragment: #F10
          returnType: void
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@method::foo2
          firstFragment: #F12
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F10 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F11
        #F2 extension type A (nameOffset:69) (firstTokenOffset:46) (offset:69)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          nextFragment: #F12
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
              nextFragment: #F13
          constructors
            #F8 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:69) (offset:69)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 69
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:75) (firstTokenOffset:71) (offset:75)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F6
                  nextFragment: #F14
              nextFragment: #F15
              previousFragment: #F5
          methods
            #F11 augment isOriginDeclaration foo (nameOffset:96) (firstTokenOffset:83) (offset:96)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F10
              nextFragment: #F16
        #F12 extension type A (nameOffset:131) (firstTokenOffset:108) (offset:131)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F2
          fields
            #F13 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:131)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F4
          constructors
            #F15 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:131) (offset:131)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 131
              formalParameters
                #F14 requiredPositional final this.it (nameOffset:137) (firstTokenOffset:133) (offset:137)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F8
          methods
            #F16 augment isOriginDeclaration foo (nameOffset:158) (firstTokenOffset:145) (offset:158)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F11
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F10
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F12 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
        #F2 extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:87) (firstTokenOffset:83) (offset:87)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
          methods
            #F13 isOriginDeclaration bar (nameOffset:97) (firstTokenOffset:95) (offset:97)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          returnType: T
        isExtensionTypeMember isOriginDeclaration bar
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F12 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:32) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F13
        #F2 extension type A (nameOffset:78) (firstTokenOffset:55) (offset:78)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
              element: #E0 T
              previousFragment: #F3
          fields
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F5
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:78) (offset:78)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 78
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:87) (firstTokenOffset:83) (offset:87)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
          methods
            #F13 augment isOriginDeclaration foo (nameOffset:105) (firstTokenOffset:95) (offset:105)
              element: <testLibrary>::@extensionType::A::@method::foo
              previousFragment: #F12
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F12
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
          constructors
            #F5 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F6 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F7
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          methods
            #F10 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@extensionType::A::@method::foo
              nextFragment: #F11
            #F12 isOriginDeclaration bar (nameOffset:50) (firstTokenOffset:45) (offset:50)
              element: <testLibrary>::@extensionType::A::@method::bar
        #F2 extension type A (nameOffset:85) (firstTokenOffset:62) (offset:85)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F8 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:85) (offset:85)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 85
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:94) (firstTokenOffset:90) (offset:94)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F6
              previousFragment: #F5
          methods
            #F11 augment isOriginDeclaration foo (nameOffset:115) (firstTokenOffset:102) (offset:115)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F6
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      methods
        isExtensionTypeMember isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@method::foo
          firstFragment: #F10
          returnType: void
        isExtensionTypeMember isOriginDeclaration bar
          reference: <testLibrary>::@extensionType::A::@method::bar
          firstFragment: #F12
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
          constructors
            #F6 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          setters
            #F11 isOriginDeclaration foo1 (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F12 requiredPositional _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
        #F2 extension type A (nameOffset:74) (firstTokenOffset:51) (offset:74)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
            #F13 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F9 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:74) (offset:74)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 74
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:80) (firstTokenOffset:76) (offset:80)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
          setters
            #F14 isOriginDeclaration foo2 (nameOffset:92) (firstTokenOffset:88) (offset:92)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              formalParameters
                #F15 requiredPositional _ (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::_
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F13
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F12
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginDeclaration foo2
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@extensionType::A::@field::foo
          constructors
            #F6 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F7 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F8
              nextFragment: #F9
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
            #F11 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@getter::foo
          setters
            #F12 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::value
              nextFragment: #F14
        #F2 extension type A (nameOffset:75) (firstTokenOffset:52) (offset:75)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F9 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 75
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:81) (firstTokenOffset:77) (offset:81)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F7
              previousFragment: #F6
          setters
            #F14 augment isOriginDeclaration foo (nameOffset:108) (firstTokenOffset:89) (offset:108)
              element: <testLibrary>::@extensionType::A::@setter::foo
              formalParameters
                #F15 requiredPositional _ (nameOffset:116) (firstTokenOffset:112) (offset:116)
                  element: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
              previousFragment: #F12
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extensionType::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::foo
          setter: <testLibrary>::@extensionType::A::@setter::foo
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F7
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
        static isExtensionTypeMember isOriginVariable foo
          reference: <testLibrary>::@extensionType::A::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::foo
      setters
        static isExtensionTypeMember isOriginVariable foo
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F4
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo1
            #F6 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::foo2
          constructors
            #F7 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F8 requiredPositional final this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  nextFragment: #F9
              nextFragment: #F10
          getters
            #F11 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
          setters
            #F12 isOriginDeclaration foo1 (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F13 requiredPositional _ (nameOffset:42) (firstTokenOffset:38) (offset:42)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
              nextFragment: #F14
            #F15 isOriginDeclaration foo2 (nameOffset:54) (firstTokenOffset:50) (offset:54)
              element: <testLibrary>::@extensionType::A::@setter::foo2
              formalParameters
                #F16 requiredPositional _ (nameOffset:63) (firstTokenOffset:59) (offset:63)
                  element: <testLibrary>::@extensionType::A::@setter::foo2::@formalParameter::_
        #F2 extension type A (nameOffset:95) (firstTokenOffset:72) (offset:95)
          element: <testLibrary>::@extensionType::A
          previousFragment: #F1
          fields
            #F4 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extensionType::A::@field::it
              previousFragment: #F3
          constructors
            #F10 augment isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:95) (offset:95)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 95
              formalParameters
                #F9 requiredPositional final this.it (nameOffset:101) (firstTokenOffset:97) (offset:101)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                  previousFragment: #F8
              previousFragment: #F7
          setters
            #F14 augment isOriginDeclaration foo1 (nameOffset:121) (firstTokenOffset:109) (offset:121)
              element: <testLibrary>::@extensionType::A::@setter::foo1
              formalParameters
                #F17 requiredPositional _ (nameOffset:130) (firstTokenOffset:126) (offset:130)
                  element: <testLibrary>::@extensionType::A::@setter::foo1::@formalParameter::_
              previousFragment: #F12
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extensionType::A::@field::foo1
          firstFragment: #F5
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extensionType::A::@field::foo2
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@extensionType::A::@setter::foo2
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F8
              type: int
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@extensionType::A::@field::it
      setters
        isExtensionTypeMember isOriginDeclaration foo1
          reference: <testLibrary>::@extensionType::A::@setter::foo1
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@extensionType::A::@field::foo1
        isExtensionTypeMember isOriginDeclaration foo2
          reference: <testLibrary>::@extensionType::A::@setter::foo2
          firstFragment: #F15
          formalParameters
            #E2 requiredPositional _
              firstFragment: #F16
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
            #F4 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          getters
            #F5 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@def::0::@field::it
          getters
            #F4 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@def::0::@getter::it
        #F5 extension type A (nameOffset:72) (firstTokenOffset:49) (offset:72)
          element: <testLibrary>::@extensionType::A::@def::1
          fields
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@extensionType::A::@def::1::@field::it
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@def::0::@field::it
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extensionType::A::@def::0::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@def::0::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@def::1::@field::it
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@extensionType::A::@def::1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@def::1::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
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
            #F10 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:93)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F5 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F6
          getters
            #F7 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
            #F6 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
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
            #F10 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
            #F7 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
              nextFragment: #F8
          getters
            #F9 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
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
            #F8 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
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
            #F13 augment isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
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
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
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
class ExtensionTypeElementTest_fromBytes extends ExtensionTypeElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ExtensionTypeElementTest_keepLinking extends ExtensionTypeElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
