// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionElementTest_keepLinking);
    defineReflectiveTests(ExtensionElementTest_fromBytes);
    defineReflectiveTests(ExtensionElementTest_augmentation_keepLinking);
    defineReflectiveTests(ExtensionElementTest_augmentation_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class ExtensionElementTest extends ElementsBaseTest {
  test_extendedType_recordType() async {
    var library = await buildLibrary('''
extension E on (int, String) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: (int, String)
      onDeclaration: <null>
''');
  }

  test_extension_documented_tripleSlash() async {
    var library = await buildLibrary('''
/// aaa
/// bbbb
/// cc
extension E on int {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:34) (firstTokenOffset:0) (offset:34)
          element: <testLibrary>::@extension::E
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      documentationComment: /// aaa\n/// bbbb\n/// cc
      extendedType: int
      onDeclaration: dart:core::@class::int
''');
  }

  test_extension_field_inferredType_const() async {
    var library = await buildLibrary('''
extension E on int {
  static const x = 0;
}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          fields
            #F2 hasInitializer isOriginDeclaration x (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@extension::E::@field::x
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @40
                  staticType: int
          getters
            #F3 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@extension::E::@getter::x
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static const hasImplicitType hasInitializer isOriginDeclaration x
          reference: <testLibrary>::@extension::E::@field::x
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@extension::E::@getter::x
      getters
        static isOriginVariable x
          reference: <testLibrary>::@extension::E::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extension::E::@field::x
''');
  }

  test_extension_lazy_all_fields() async {
    var library = await buildLibrary('''
extension E on int {
  static int foo = 42;
}
''');

    var fields = library.getExtension('E')!.fields;
    expect(fields, hasLength(1));
  }

  test_extension_lazy_all_getters() async {
    var library = await buildLibrary('''
extension E on int {
  int get foo => 0;
}
''');

    var getters = library.getExtension('E')!.getters;
    expect(getters, hasLength(1));
  }

  test_extension_lazy_all_methods() async {
    var library = await buildLibrary('''
extension E on int {
  void foo() {}
}
''');

    var methods = library.getExtension('E')!.methods;
    expect(methods, hasLength(1));
  }

  test_extension_lazy_all_setters() async {
    var library = await buildLibrary('''
extension E on int {
  set foo(int _) {}
}
''');

    var setters = library.getExtension('E')!.setters;
    expect(setters, hasLength(1));
  }

  test_extension_lazy_byReference_field() async {
    var library = await buildLibrary('''
extension E on int {
  static int foo = 42;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtension('E')!;
    var foo = getElementOfReference(E, ['@field', 'foo']);
    expect(foo.name, 'foo');
  }

  test_extension_lazy_byReference_getter() async {
    var library = await buildLibrary('''
extension E on int {
  int get foo => 0;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtension('E')!;
    var foo = getElementOfReference(E, ['@getter', 'foo']);
    expect(foo.name, 'foo');
  }

  test_extension_lazy_byReference_method() async {
    var library = await buildLibrary('''
extension E on int {
  void foo() {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtension('E')!;
    var foo = getElementOfReference(E, ['@method', 'foo']);
    expect(foo.name, 'foo');
  }

  test_extension_lazy_byReference_setter() async {
    var library = await buildLibrary('''
extension E on int {
  set foo(int _) {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getExtension('E')!;
    var foo = getElementOfReference(E, ['@setter', 'foo']);
    expect(foo.name, 'foo');
  }

  test_extension_typeParameters_hasBound() async {
    var library = await buildLibrary('''
extension E<T extends num> on int {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: num
      extendedType: int
      onDeclaration: dart:core::@class::int
''');
  }

  test_extension_typeParameters_noBound() async {
    var library = await buildLibrary('''
extension E<T> on int {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      extendedType: int
      onDeclaration: dart:core::@class::int
''');
  }

  test_getter_ofGeneric_refEnclosingTypeParameter_false() async {
    var library = await buildLibrary('''
extension E<T> on List<T> {
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
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
          fields
            #F3 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::E::@field::foo
          getters
            #F4 isOriginDeclaration foo (nameOffset:38) (firstTokenOffset:30) (offset:38)
              element: <testLibrary>::@extension::E::@getter::foo
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      extendedType: List<T>
      onDeclaration: dart:core::@class::List
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@extension::E::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::E::@getter::foo
      getters
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::E::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extension::E::@field::foo
''');
  }

  test_getter_ofGeneric_refEnclosingTypeParameter_true() async {
    var library = await buildLibrary('''
extension E<T> on List<T> {
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
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
          fields
            #F3 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::E::@field::foo
          getters
            #F4 isOriginDeclaration foo (nameOffset:36) (firstTokenOffset:30) (offset:36)
              element: <testLibrary>::@extension::E::@getter::foo
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      extendedType: List<T>
      onDeclaration: dart:core::@class::List
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@extension::E::@field::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extension::E::@getter::foo
      getters
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::E::@getter::foo
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extension::E::@field::foo
''');
  }

  test_metadata_extension_scope() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
extension E<@foo T> on int {
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
                  element: <testLibrary>::@getter::foo
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: <testLibrary>::@extension::E::@field::foo
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @71
                  staticType: int
          getters
            #F4 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@extension::E::@getter::foo
          methods
            #F5 isOriginDeclaration bar (nameOffset:88) (firstTokenOffset:76) (offset:88)
              element: <testLibrary>::@extension::E::@method::bar
              metadata
                Annotation
                  atSign: @ @76
                  name: SimpleIdentifier
                    token: foo @77
                    element: <testLibrary>::@extension::E::@getter::foo
                    staticType: null
                  element: <testLibrary>::@extension::E::@getter::foo
      topLevelVariables
        #F6 hasInitializer isOriginDeclaration foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_1
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F7 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
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
              element: <testLibrary>::@getter::foo
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static const hasImplicitType hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::E::@field::foo
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@extension::E::@getter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::E::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extension::E::@field::foo
      methods
        isOriginDeclaration bar
          reference: <testLibrary>::@extension::E::@method::bar
          firstFragment: #F5
          metadata
            Annotation
              atSign: @ @76
              name: SimpleIdentifier
                token: foo @77
                element: <testLibrary>::@extension::E::@getter::foo
                staticType: null
              element: <testLibrary>::@extension::E::@getter::foo
          returnType: void
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F6
      type: int
      constantInitializer
        fragment: #F6
        expression: expression_1
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_extensionDeclaration() async {
    var library = await buildLibrary(r'''
const a = null;
class A {}
@a
@Object()
extension E on A {}''');
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
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        #F3 extension E (nameOffset:50) (firstTokenOffset:27) (offset:50)
          element: <testLibrary>::@extension::E
      topLevelVariables
        #F4 hasInitializer isOriginDeclaration a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            NullLiteral
              literal: null @10
              staticType: Null
      getters
        #F5 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: A
      onDeclaration: <testLibrary>::@class::A
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: dynamic
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_method() async {
    var library = await buildLibrary('''
extension E on int {
  void foo() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          methods
            #F2 isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:23) (offset:28)
              element: <testLibrary>::@extension::E::@method::foo
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::E::@method::foo
          firstFragment: #F2
          returnType: void
''');
  }

  test_method_ofGeneric_refEnclosingTypeParameter_false() async {
    var library = await buildLibrary('''
extension E<T> on List<T> {
  void foo() {}
}
''');
    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
          methods
            #F3 isOriginDeclaration foo (nameOffset:35) (firstTokenOffset:30) (offset:35)
              element: <testLibrary>::@extension::E::@method::foo
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      extendedType: List<T>
      onDeclaration: dart:core::@class::List
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::E::@method::foo
          firstFragment: #F3
          returnType: void
''');
  }

  test_method_ofGeneric_refEnclosingTypeParameter_true() async {
    var library = await buildLibrary('''
extension E<T> on List<T> {
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
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
          methods
            #F3 isOriginDeclaration foo (nameOffset:35) (firstTokenOffset:30) (offset:35)
              element: <testLibrary>::@extension::E::@method::foo
              formalParameters
                #F4 requiredPositional _ (nameOffset:41) (firstTokenOffset:39) (offset:41)
                  element: <testLibrary>::@extension::E::@method::foo::@formalParameter::_
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      extendedType: List<T>
      onDeclaration: dart:core::@class::List
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::E::@method::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F4
              type: T
          returnType: void
''');
  }

  test_nonSynthetic_extension_getter() async {
    var library = await buildLibrary(r'''
extension E on int {
  int get foo => 0;
}
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::E::@field::foo
          getters
            #F3 isOriginDeclaration foo (nameOffset:31) (firstTokenOffset:23) (offset:31)
              element: <testLibrary>::@extension::E::@getter::foo
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@extension::E::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extension::E::@getter::foo
      getters
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::E::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extension::E::@field::foo
''');
  }

  test_nonSynthetic_extension_setter() async {
    var library = await buildLibrary(r'''
extension E on int {
  set foo(int value) {}
}
''');
    configuration.withNonSynthetic = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::E::@field::foo
          setters
            #F3 isOriginDeclaration foo (nameOffset:27) (firstTokenOffset:23) (offset:27)
              element: <testLibrary>::@extension::E::@setter::foo
              formalParameters
                #F4 requiredPositional value (nameOffset:35) (firstTokenOffset:31) (offset:35)
                  element: <testLibrary>::@extension::E::@setter::foo::@formalParameter::value
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@extension::E::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@extension::E::@setter::foo
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::E::@setter::foo
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F4
              type: int
          returnType: void
          variable: <testLibrary>::@extension::E::@field::foo
''');
  }

  test_onDeclaration_class() async {
    var library = await buildLibrary('''
class A {}
extension E on A {}
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
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        #F3 extension E (nameOffset:21) (firstTokenOffset:11) (offset:21)
          element: <testLibrary>::@extension::E
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: A
      onDeclaration: <testLibrary>::@class::A
''');
  }

  test_onDeclaration_dynamic() async {
    var library = await buildLibrary('''
extension E on dynamic {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: dynamic
      onDeclaration: <null>
''');
  }

  test_onDeclaration_enum() async {
    var library = await buildLibrary('''
enum A { foo; }
extension E on A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasInitializer isOriginDeclaration foo (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: foo @-1
                      element: <testLibrary>::@enum::A::@getter::foo
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::A::@getter::foo
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
      extensions
        #F7 extension E (nameOffset:26) (firstTokenOffset:16) (offset:26)
          element: <testLibrary>::@extension::E
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::foo
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::foo
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F7
      extendedType: A
      onDeclaration: <testLibrary>::@enum::A
''');
  }

  test_onDeclaration_extensionType() async {
    var library = await buildLibrary('''
extension type A(Object? it) {}
extension E on A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:42) (firstTokenOffset:32) (offset:42)
          element: <testLibrary>::@extension::E
      extensionTypes
        #F2 extension type A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::A
          fields
            #F3 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@field::it
          constructors
            #F4 isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::A::@constructor::new
              typeName: A
              typeNameOffset: 15
              formalParameters
                #F5 requiredPositional final this.it (nameOffset:25) (firstTokenOffset:17) (offset:25)
                  element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          getters
            #F6 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::A::@getter::it
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: A
      onDeclaration: <testLibrary>::@extensionType::A
  extensionTypes
    extension type A
      reference: <testLibrary>::@extensionType::A
      firstFragment: #F2
      representation: <testLibrary>::@extensionType::A::@field::it
      primaryConstructor: <testLibrary>::@extensionType::A::@constructor::new
      typeErasure: Object?
      fields
        final isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::A::@field::it
          firstFragment: #F3
          type: Object?
          getter: <testLibrary>::@extensionType::A::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional final declaring this.it
              firstFragment: #F5
              type: Object?
              field: <testLibrary>::@extensionType::A::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::A::@getter::it
          firstFragment: #F6
          returnType: Object?
          variable: <testLibrary>::@extensionType::A::@field::it
''');
  }

  test_onDeclaration_futureOr() async {
    var library = await buildLibrary('''
import 'dart:async';
extension E on FutureOr<int> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      extensions
        #F1 extension E (nameOffset:31) (firstTokenOffset:21) (offset:31)
          element: <testLibrary>::@extension::E
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: FutureOr<int>
      onDeclaration: <null>
''');
  }

  test_onDeclaration_mixin() async {
    var library = await buildLibrary('''
mixin A {}
extension E on A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:21) (firstTokenOffset:11) (offset:21)
          element: <testLibrary>::@extension::E
      mixins
        #F2 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: A
      onDeclaration: <testLibrary>::@mixin::A
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F2
      superclassConstraints
        Object
''');
  }

  test_onDeclaration_Never() async {
    var library = await buildLibrary('''
extension E on Never {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: Never
      onDeclaration: <null>
''');
  }

  test_onDeclaration_nullable() async {
    var library = await buildLibrary('''
extension E on int? {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: int?
      onDeclaration: <null>
''');
  }

  test_onDeclaration_typedef() async {
    var library = await buildLibrary('''
typedef A = int;
extension E on A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:27) (firstTokenOffset:17) (offset:27)
          element: <testLibrary>::@extension::E
      typeAliases
        #F2 A (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::A
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: int
        alias: <testLibrary>::@typeAlias::A
      onDeclaration: dart:core::@class::int
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F2
      aliasedType: int
''');
  }

  test_onDeclaration_typeParameter() async {
    var library = await buildLibrary('''
extension E<X> on X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 X (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 X
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
      extendedType: X
      onDeclaration: <null>
''');
  }

  test_onDeclaration_void() async {
    var library = await buildLibrary('''
extension E on void {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: void
      onDeclaration: <null>
''');
  }

  test_unnamed() async {
    var library = await buildLibrary('''
extension on int {}
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
  extensions
    extension <null-name>
      reference: <testLibrary>::@extension::0
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
''');
  }
}

abstract class ExtensionElementTest_augmentation extends ElementsBaseTest {
  test_augmentationTarget() async {
    var library = await buildLibrary(r'''
extension A on int {}

augment extension A {}

augment extension A {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
        #F2 extension A (nameOffset:41) (firstTokenOffset:23) (offset:41)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F3
        #F3 extension A (nameOffset:65) (firstTokenOffset:47) (offset:65)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
  exportedReferences
    declared <testLibrary>::@extension::A
  exportNamespace
    A: <testLibrary>::@extension::A
''');
  }

  test_augmentationTarget_no2() async {
    var library = await buildLibrary(r'''
augment extension A {
  void foo1() {}
}

augment extension A {
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:18) (firstTokenOffset:0) (offset:18)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          methods
            #F3 isOriginDeclaration foo1 (nameOffset:29) (firstTokenOffset:24) (offset:29)
              element: <testLibrary>::@extension::A::@method::foo1
        #F2 extension A (nameOffset:60) (firstTokenOffset:42) (offset:60)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          methods
            #F4 isOriginDeclaration foo2 (nameOffset:71) (firstTokenOffset:66) (offset:71)
              element: <testLibrary>::@extension::A::@method::foo2
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: InvalidType
      onDeclaration: <null>
      methods
        isOriginDeclaration foo1
          reference: <testLibrary>::@extension::A::@method::foo1
          firstFragment: #F3
          returnType: void
        isOriginDeclaration foo2
          reference: <testLibrary>::@extension::A::@method::foo2
          firstFragment: #F4
          returnType: void
''');
  }

  test_augmented_field_augment_field() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo = 0;
}

augment extension A {
  augment static int foo = 1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo
              nextFragment: #F4
          getters
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo
          setters
            #F6 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::value
        #F2 extension A (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer isOriginDeclaration foo (nameOffset:89) (firstTokenOffset:89) (offset:89)
              element: <testLibrary>::@extension::A::@field::foo
              previousFragment: #F3
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
          setter: <testLibrary>::@extension::A::@setter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
      setters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_field_augment_field2() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo = 0;
}

augment extension A {
  augment static int foo = 1;
}

augment extension A {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo
              nextFragment: #F4
          getters
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo
          setters
            #F6 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::value
        #F2 extension A (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F8
          fields
            #F4 augment hasInitializer isOriginDeclaration foo (nameOffset:89) (firstTokenOffset:89) (offset:89)
              element: <testLibrary>::@extension::A::@field::foo
              previousFragment: #F3
              nextFragment: #F9
        #F8 extension A (nameOffset:119) (firstTokenOffset:101) (offset:119)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          fields
            #F9 augment hasInitializer isOriginDeclaration foo (nameOffset:144) (firstTokenOffset:144) (offset:144)
              element: <testLibrary>::@extension::A::@field::foo
              previousFragment: #F4
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
          setter: <testLibrary>::@extension::A::@setter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
      setters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo = 0;
}

augment extension A {
  augment static int get foo => 1;
}

augment extension A {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo
              nextFragment: #F4
          getters
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo
              nextFragment: #F6
          setters
            #F7 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::value
        #F2 extension A (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F9
          getters
            #F6 augment isOriginDeclaration foo (nameOffset:93) (firstTokenOffset:70) (offset:93)
              element: <testLibrary>::@extension::A::@getter::foo
              previousFragment: #F5
        #F9 extension A (nameOffset:124) (firstTokenOffset:106) (offset:124)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          fields
            #F4 augment hasInitializer isOriginDeclaration foo (nameOffset:149) (firstTokenOffset:149) (offset:149)
              element: <testLibrary>::@extension::A::@field::foo
              previousFragment: #F3
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
          setter: <testLibrary>::@extension::A::@setter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
      setters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo = 0;
}

augment extension A {
  augment static set foo(int _) {}
}

augment extension A {
  augment static int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo
              nextFragment: #F4
          getters
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo
          setters
            #F6 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::value
              nextFragment: #F8
        #F2 extension A (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F9
          setters
            #F8 augment isOriginDeclaration foo (nameOffset:89) (firstTokenOffset:70) (offset:89)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F10 requiredPositional _ (nameOffset:97) (firstTokenOffset:93) (offset:97)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::_
              previousFragment: #F6
        #F9 extension A (nameOffset:124) (firstTokenOffset:106) (offset:124)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          fields
            #F4 augment hasInitializer isOriginDeclaration foo (nameOffset:149) (firstTokenOffset:149) (offset:149)
              element: <testLibrary>::@extension::A::@field::foo
              previousFragment: #F3
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
          setter: <testLibrary>::@extension::A::@setter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
      setters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo = 0;
}

augment extension A {
  augment static double foo = 1.2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo
              nextFragment: #F4
          getters
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo
          setters
            #F6 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::value
        #F2 extension A (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer isOriginDeclaration foo (nameOffset:92) (firstTokenOffset:92) (offset:92)
              element: <testLibrary>::@extension::A::@field::foo
              previousFragment: #F3
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
          setter: <testLibrary>::@extension::A::@setter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
      setters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_field_augment_getter() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int get foo => 0;
}

augment extension A {
  augment static int foo = 1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo
              nextFragment: #F4
          getters
            #F5 isOriginDeclaration foo (nameOffset:38) (firstTokenOffset:23) (offset:38)
              element: <testLibrary>::@extension::A::@getter::foo
        #F2 extension A (nameOffset:69) (firstTokenOffset:51) (offset:69)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer isOriginDeclaration foo (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@extension::A::@field::foo
              previousFragment: #F3
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginGetterSetter foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
      getters
        static isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_fields_add() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo1 = 0;
}

augment extension A {
  static int foo2 = 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo1 (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo1
          getters
            #F4 isOriginVariable foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo1
          setters
            #F5 isOriginVariable foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo1
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo1::@formalParameter::value
        #F2 extension A (nameOffset:65) (firstTokenOffset:47) (offset:65)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          fields
            #F7 hasInitializer isOriginDeclaration foo2 (nameOffset:82) (firstTokenOffset:82) (offset:82)
              element: <testLibrary>::@extension::A::@field::foo2
          getters
            #F8 isOriginVariable foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
              element: <testLibrary>::@extension::A::@getter::foo2
          setters
            #F9 isOriginVariable foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
              element: <testLibrary>::@extension::A::@setter::foo2
              formalParameters
                #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:82)
                  element: <testLibrary>::@extension::A::@setter::foo2::@formalParameter::value
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo1
          reference: <testLibrary>::@extension::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo1
          setter: <testLibrary>::@extension::A::@setter::foo1
        static hasInitializer isOriginDeclaration foo2
          reference: <testLibrary>::@extension::A::@field::foo2
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo2
          setter: <testLibrary>::@extension::A::@setter::foo2
      getters
        static isOriginVariable foo1
          reference: <testLibrary>::@extension::A::@getter::foo1
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo1
        static isOriginVariable foo2
          reference: <testLibrary>::@extension::A::@getter::foo2
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo2
      setters
        static isOriginVariable foo1
          reference: <testLibrary>::@extension::A::@setter::foo1
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo1
        static isOriginVariable foo2
          reference: <testLibrary>::@extension::A::@setter::foo2
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo2
''');
  }

  test_augmented_getters_add() async {
    var library = await buildLibrary(r'''
extension A on int {
  int get foo1 => 0;
}

augment extension A {
  int get foo2 => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo1
          getters
            #F4 isOriginDeclaration foo1 (nameOffset:31) (firstTokenOffset:23) (offset:31)
              element: <testLibrary>::@extension::A::@getter::foo1
        #F2 extension A (nameOffset:63) (firstTokenOffset:45) (offset:63)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          fields
            #F5 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@extension::A::@field::foo2
          getters
            #F6 isOriginDeclaration foo2 (nameOffset:77) (firstTokenOffset:69) (offset:77)
              element: <testLibrary>::@extension::A::@getter::foo2
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extension::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extension::A::@field::foo2
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo2
      getters
        isOriginDeclaration foo1
          reference: <testLibrary>::@extension::A::@getter::foo1
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo1
        isOriginDeclaration foo2
          reference: <testLibrary>::@extension::A::@getter::foo2
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    var library = await buildLibrary(r'''
extension A<T> on int {
  T get foo1;
}

augment extension A<T> {
  T get foo2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo1
          getters
            #F6 isOriginDeclaration foo1 (nameOffset:32) (firstTokenOffset:26) (offset:32)
              element: <testLibrary>::@extension::A::@getter::foo1
        #F2 extension A (nameOffset:59) (firstTokenOffset:41) (offset:59)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:61) (firstTokenOffset:61) (offset:61)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@extension::A::@field::foo2
          getters
            #F8 isOriginDeclaration foo2 (nameOffset:74) (firstTokenOffset:68) (offset:74)
              element: <testLibrary>::@extension::A::@getter::foo2
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extension::A::@field::foo1
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extension::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extension::A::@field::foo2
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@extension::A::@getter::foo2
      getters
        abstract isOriginDeclaration foo1
          reference: <testLibrary>::@extension::A::@getter::foo1
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extension::A::@field::foo1
        abstract isOriginDeclaration foo2
          reference: <testLibrary>::@extension::A::@getter::foo2
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@extension::A::@field::foo2
''');
  }

  test_augmented_getters_augment_field() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo = 0;
}

augment extension A {
  augment static int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo
          getters
            #F4 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo
              nextFragment: #F5
          setters
            #F6 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::value
        #F2 extension A (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          getters
            #F5 augment isOriginDeclaration foo (nameOffset:93) (firstTokenOffset:70) (offset:93)
              element: <testLibrary>::@extension::A::@getter::foo
              previousFragment: #F4
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
          setter: <testLibrary>::@extension::A::@setter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
      setters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_getters_augment_field2() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo = 0;
}

augment extension A {
  augment static int get foo => 0;
}

augment extension A {
  augment static int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo
          getters
            #F4 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo
              nextFragment: #F5
          setters
            #F6 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::value
        #F2 extension A (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F8
          getters
            #F5 augment isOriginDeclaration foo (nameOffset:93) (firstTokenOffset:70) (offset:93)
              element: <testLibrary>::@extension::A::@getter::foo
              previousFragment: #F4
              nextFragment: #F9
        #F8 extension A (nameOffset:124) (firstTokenOffset:106) (offset:124)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          getters
            #F9 augment isOriginDeclaration foo (nameOffset:153) (firstTokenOffset:130) (offset:153)
              element: <testLibrary>::@extension::A::@getter::foo
              previousFragment: #F5
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
          setter: <testLibrary>::@extension::A::@setter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
      setters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_getters_augment_getter() async {
    var library = await buildLibrary(r'''
extension A on int {
  int get foo1 => 0;
  int get foo2 => 0;
}

augment extension A {
  augment int get foo1 => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo1
            #F4 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo2
          getters
            #F5 isOriginDeclaration foo1 (nameOffset:31) (firstTokenOffset:23) (offset:31)
              element: <testLibrary>::@extension::A::@getter::foo1
              nextFragment: #F6
            #F7 isOriginDeclaration foo2 (nameOffset:52) (firstTokenOffset:44) (offset:52)
              element: <testLibrary>::@extension::A::@getter::foo2
        #F2 extension A (nameOffset:84) (firstTokenOffset:66) (offset:84)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          getters
            #F6 augment isOriginDeclaration foo1 (nameOffset:106) (firstTokenOffset:90) (offset:106)
              element: <testLibrary>::@extension::A::@getter::foo1
              previousFragment: #F5
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extension::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extension::A::@field::foo2
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo2
      getters
        isOriginDeclaration foo1
          reference: <testLibrary>::@extension::A::@getter::foo1
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo1
        isOriginDeclaration foo2
          reference: <testLibrary>::@extension::A::@getter::foo2
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo2
''');
  }

  test_augmented_getters_augment_getter2() async {
    var library = await buildLibrary(r'''
extension A on int {
  int get foo => 0;
}

augment extension A {
  augment int get foo => 0;
}

augment extension A {
  augment int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo
          getters
            #F4 isOriginDeclaration foo (nameOffset:31) (firstTokenOffset:23) (offset:31)
              element: <testLibrary>::@extension::A::@getter::foo
              nextFragment: #F5
        #F2 extension A (nameOffset:62) (firstTokenOffset:44) (offset:62)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F6
          getters
            #F5 augment isOriginDeclaration foo (nameOffset:84) (firstTokenOffset:68) (offset:84)
              element: <testLibrary>::@extension::A::@getter::foo
              previousFragment: #F4
              nextFragment: #F7
        #F6 extension A (nameOffset:115) (firstTokenOffset:97) (offset:115)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          getters
            #F7 augment isOriginDeclaration foo (nameOffset:137) (firstTokenOffset:121) (offset:137)
              element: <testLibrary>::@extension::A::@getter::foo
              previousFragment: #F5
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
      getters
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_methods() async {
    var library = await buildLibrary(r'''
extension A on int {
  void foo() {}
}

augment extension A {
  void bar() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          methods
            #F3 isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:23) (offset:28)
              element: <testLibrary>::@extension::A::@method::foo
        #F2 extension A (nameOffset:58) (firstTokenOffset:40) (offset:58)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          methods
            #F4 isOriginDeclaration bar (nameOffset:69) (firstTokenOffset:64) (offset:69)
              element: <testLibrary>::@extension::A::@method::bar
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@method::foo
          firstFragment: #F3
          returnType: void
        isOriginDeclaration bar
          reference: <testLibrary>::@extension::A::@method::bar
          firstFragment: #F4
          returnType: void
''');
  }

  test_augmented_methods_augment() async {
    var library = await buildLibrary(r'''
extension A on int {
  void foo1() {}
  void foo2() {}
}

augment extension A {
  augment void foo1() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          methods
            #F3 isOriginDeclaration foo1 (nameOffset:28) (firstTokenOffset:23) (offset:28)
              element: <testLibrary>::@extension::A::@method::foo1
              nextFragment: #F4
            #F5 isOriginDeclaration foo2 (nameOffset:45) (firstTokenOffset:40) (offset:45)
              element: <testLibrary>::@extension::A::@method::foo2
        #F2 extension A (nameOffset:76) (firstTokenOffset:58) (offset:76)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          methods
            #F4 augment isOriginDeclaration foo1 (nameOffset:95) (firstTokenOffset:82) (offset:95)
              element: <testLibrary>::@extension::A::@method::foo1
              previousFragment: #F3
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      methods
        isOriginDeclaration foo1
          reference: <testLibrary>::@extension::A::@method::foo1
          firstFragment: #F3
          returnType: void
        isOriginDeclaration foo2
          reference: <testLibrary>::@extension::A::@method::foo2
          firstFragment: #F5
          returnType: void
''');
  }

  test_augmented_methods_augment2() async {
    var library = await buildLibrary(r'''
extension A on int {
  void foo() {}
}

augment extension A {
  augment void foo() {}
}

augment extension A {
  augment void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          methods
            #F3 isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:23) (offset:28)
              element: <testLibrary>::@extension::A::@method::foo
              nextFragment: #F4
        #F2 extension A (nameOffset:58) (firstTokenOffset:40) (offset:58)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F5
          methods
            #F4 augment isOriginDeclaration foo (nameOffset:77) (firstTokenOffset:64) (offset:77)
              element: <testLibrary>::@extension::A::@method::foo
              previousFragment: #F3
              nextFragment: #F6
        #F5 extension A (nameOffset:107) (firstTokenOffset:89) (offset:107)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          methods
            #F6 augment isOriginDeclaration foo (nameOffset:126) (firstTokenOffset:113) (offset:126)
              element: <testLibrary>::@extension::A::@method::foo
              previousFragment: #F4
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@method::foo
          firstFragment: #F3
          returnType: void
''');
  }

  test_augmented_methods_generic() async {
    var library = await buildLibrary(r'''
extension A<T> on int {
  T foo() => throw 0;
}

augment extension A<T> {
  T bar() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
              nextFragment: #F4
          methods
            #F5 isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:26) (offset:28)
              element: <testLibrary>::@extension::A::@method::foo
        #F2 extension A (nameOffset:67) (firstTokenOffset:49) (offset:67)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:69) (firstTokenOffset:69) (offset:69)
              element: #E0 T
              previousFragment: #F3
          methods
            #F6 isOriginDeclaration bar (nameOffset:78) (firstTokenOffset:76) (offset:78)
              element: <testLibrary>::@extension::A::@method::bar
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      extendedType: int
      onDeclaration: dart:core::@class::int
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@method::foo
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          returnType: T
        isOriginDeclaration bar
          reference: <testLibrary>::@extension::A::@method::bar
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_methods_generic_augment() async {
    var library = await buildLibrary(r'''
extension A<T> on int {
  T foo() => throw 0;
}

augment extension A<T> {
  augment T foo() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
              nextFragment: #F4
          methods
            #F5 isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:26) (offset:28)
              element: <testLibrary>::@extension::A::@method::foo
              nextFragment: #F6
        #F2 extension A (nameOffset:67) (firstTokenOffset:49) (offset:67)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:69) (firstTokenOffset:69) (offset:69)
              element: #E0 T
              previousFragment: #F3
          methods
            #F6 augment isOriginDeclaration foo (nameOffset:86) (firstTokenOffset:76) (offset:86)
              element: <testLibrary>::@extension::A::@method::foo
              previousFragment: #F5
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      extendedType: int
      onDeclaration: dart:core::@class::int
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@method::foo
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_methods_typeParameterCountMismatch() async {
    var library = await buildLibrary(r'''
extension A on int {
  void foo() {}
  void bar() {}
}

augment extension A<T> {
  augment void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          methods
            #F3 isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:23) (offset:28)
              element: <testLibrary>::@extension::A::@method::foo
              nextFragment: #F4
            #F5 isOriginDeclaration bar (nameOffset:44) (firstTokenOffset:39) (offset:44)
              element: <testLibrary>::@extension::A::@method::bar
        #F2 extension A (nameOffset:74) (firstTokenOffset:56) (offset:74)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          methods
            #F4 augment isOriginDeclaration foo (nameOffset:96) (firstTokenOffset:83) (offset:96)
              element: <testLibrary>::@extension::A::@method::foo
              previousFragment: #F3
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@method::foo
          firstFragment: #F3
          returnType: void
        isOriginDeclaration bar
          reference: <testLibrary>::@extension::A::@method::bar
          firstFragment: #F5
          returnType: void
''');
  }

  test_augmented_setters_add() async {
    var library = await buildLibrary(r'''
extension A on int {
  set foo1(int _) {}
}

augment extension A {
  set foo2(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo1
          setters
            #F4 isOriginDeclaration foo1 (nameOffset:27) (firstTokenOffset:23) (offset:27)
              element: <testLibrary>::@extension::A::@setter::foo1
              formalParameters
                #F5 requiredPositional _ (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@extension::A::@setter::foo1::@formalParameter::_
        #F2 extension A (nameOffset:63) (firstTokenOffset:45) (offset:63)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          fields
            #F6 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:63)
              element: <testLibrary>::@extension::A::@field::foo2
          setters
            #F7 isOriginDeclaration foo2 (nameOffset:73) (firstTokenOffset:69) (offset:73)
              element: <testLibrary>::@extension::A::@setter::foo2
              formalParameters
                #F8 requiredPositional _ (nameOffset:82) (firstTokenOffset:78) (offset:82)
                  element: <testLibrary>::@extension::A::@setter::foo2::@formalParameter::_
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extension::A::@field::foo1
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@extension::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extension::A::@field::foo2
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@extension::A::@setter::foo2
      setters
        isOriginDeclaration foo1
          reference: <testLibrary>::@extension::A::@setter::foo1
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo1
        isOriginDeclaration foo2
          reference: <testLibrary>::@extension::A::@setter::foo2
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo2
''');
  }

  test_augmented_setters_augment_field() async {
    var library = await buildLibrary(r'''
extension A on int {
  static int foo = 0;
}

augment extension A {
  augment static set foo(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 hasInitializer isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@extension::A::@field::foo
          getters
            #F4 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@getter::foo
          setters
            #F5 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::value
              nextFragment: #F7
        #F2 extension A (nameOffset:64) (firstTokenOffset:46) (offset:64)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          setters
            #F7 augment isOriginDeclaration foo (nameOffset:89) (firstTokenOffset:70) (offset:89)
              element: <testLibrary>::@extension::A::@setter::foo
              formalParameters
                #F8 requiredPositional _ (nameOffset:97) (firstTokenOffset:93) (offset:97)
                  element: <testLibrary>::@extension::A::@setter::foo::@formalParameter::_
              previousFragment: #F5
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        static hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@extension::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@extension::A::@getter::foo
          setter: <testLibrary>::@extension::A::@setter::foo
      getters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@extension::A::@field::foo
      setters
        static isOriginVariable foo
          reference: <testLibrary>::@extension::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo
''');
  }

  test_augmented_setters_augment_setter() async {
    var library = await buildLibrary(r'''
extension A on int {
  set foo1(int _) {}
  set foo2(int _) {}
}

augment extension A {
  augment set foo1(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          fields
            #F3 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo1
            #F4 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@extension::A::@field::foo2
          setters
            #F5 isOriginDeclaration foo1 (nameOffset:27) (firstTokenOffset:23) (offset:27)
              element: <testLibrary>::@extension::A::@setter::foo1
              formalParameters
                #F6 requiredPositional _ (nameOffset:36) (firstTokenOffset:32) (offset:36)
                  element: <testLibrary>::@extension::A::@setter::foo1::@formalParameter::_
              nextFragment: #F7
            #F8 isOriginDeclaration foo2 (nameOffset:48) (firstTokenOffset:44) (offset:48)
              element: <testLibrary>::@extension::A::@setter::foo2
              formalParameters
                #F9 requiredPositional _ (nameOffset:57) (firstTokenOffset:53) (offset:57)
                  element: <testLibrary>::@extension::A::@setter::foo2::@formalParameter::_
        #F2 extension A (nameOffset:84) (firstTokenOffset:66) (offset:84)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          setters
            #F7 augment isOriginDeclaration foo1 (nameOffset:102) (firstTokenOffset:90) (offset:102)
              element: <testLibrary>::@extension::A::@setter::foo1
              formalParameters
                #F10 requiredPositional _ (nameOffset:111) (firstTokenOffset:107) (offset:111)
                  element: <testLibrary>::@extension::A::@setter::foo1::@formalParameter::_
              previousFragment: #F5
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        isOriginGetterSetter foo1
          reference: <testLibrary>::@extension::A::@field::foo1
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@extension::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@extension::A::@field::foo2
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@extension::A::@setter::foo2
      setters
        isOriginDeclaration foo1
          reference: <testLibrary>::@extension::A::@setter::foo1
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo1
        isOriginDeclaration foo2
          reference: <testLibrary>::@extension::A::@setter::foo2
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@extension::A::@field::foo2
''');
  }

  test_augmentedBy_class2() async {
    var library = await buildLibrary(r'''
extension A on int {}

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
        #F1 class A (nameOffset:37) (firstTokenOffset:23) (offset:37)
          element: <testLibrary>::@class::A
          nextFragment: #F2
        #F2 class A (nameOffset:57) (firstTokenOffset:43) (offset:57)
          element: <testLibrary>::@class::A
          previousFragment: #F1
      extensions
        #F3 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F3
      extendedType: int
      onDeclaration: dart:core::@class::int
''');
  }

  test_augmentedBy_class_extension() async {
    var library = await buildLibrary(r'''
extension A on int {}

augment class A {}

augment extension A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:37) (firstTokenOffset:23) (offset:37)
          element: <testLibrary>::@class::A
      extensions
        #F2 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A::@def::0
        #F3 extension A (nameOffset:61) (firstTokenOffset:43) (offset:61)
          element: <testLibrary>::@extension::A::@def::1
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
  extensions
    extension A
      reference: <testLibrary>::@extension::A::@def::0
      firstFragment: #F2
      extendedType: int
      onDeclaration: dart:core::@class::int
    extension A
      reference: <testLibrary>::@extension::A::@def::1
      firstFragment: #F3
      extendedType: InvalidType
      onDeclaration: <null>
''');
  }

  test_onClause_augmentation() async {
    var library = await buildLibrary(r'''
extension A on int {}

augment extension A on double {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
        #F2 extension A (nameOffset:41) (firstTokenOffset:23) (offset:41)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
  exportedReferences
    declared <testLibrary>::@extension::A
  exportNamespace
    A: <testLibrary>::@extension::A
''');
  }

  test_typeParameters_111() async {
    var library = await buildLibrary(r'''
extension A<T> on int {}
augment extension A<T> {}
augment extension A<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
              nextFragment: #F4
        #F2 extension A (nameOffset:43) (firstTokenOffset:25) (offset:43)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F5
          typeParameters
            #F4 T (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F6
        #F5 extension A (nameOffset:69) (firstTokenOffset:51) (offset:69)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          typeParameters
            #F6 T (nameOffset:71) (firstTokenOffset:71) (offset:71)
              element: #E0 T
              previousFragment: #F4
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      extendedType: int
      onDeclaration: dart:core::@class::int
''');
  }

  test_typeParameters_121() async {
    var library = await buildLibrary(r'''
extension A<T> on int {}
augment extension A<T, U> {}
augment extension A<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
              nextFragment: #F4
        #F2 extension A (nameOffset:43) (firstTokenOffset:25) (offset:43)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F5
          typeParameters
            #F4 T (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F6
        #F5 extension A (nameOffset:72) (firstTokenOffset:54) (offset:72)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          typeParameters
            #F6 T (nameOffset:74) (firstTokenOffset:74) (offset:74)
              element: #E0 T
              previousFragment: #F4
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      extendedType: int
      onDeclaration: dart:core::@class::int
''');
  }

  test_typeParameters_212() async {
    var library = await buildLibrary(r'''
extension A<T, U> on int {}
augment extension A<T> {}
augment extension A<T, U> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension A (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: #E1 U
              nextFragment: #F6
        #F2 extension A (nameOffset:46) (firstTokenOffset:28) (offset:46)
          element: <testLibrary>::@extension::A
          previousFragment: #F1
          nextFragment: #F7
          typeParameters
            #F4 T (nameOffset:48) (firstTokenOffset:48) (offset:48)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F8
            #F6 U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F9
        #F7 extension A (nameOffset:72) (firstTokenOffset:54) (offset:72)
          element: <testLibrary>::@extension::A
          previousFragment: #F2
          typeParameters
            #F8 T (nameOffset:74) (firstTokenOffset:74) (offset:74)
              element: #E0 T
              previousFragment: #F4
            #F9 U (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: #E1 U
              previousFragment: #F6
  extensions
    extension A
      reference: <testLibrary>::@extension::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
      extendedType: int
      onDeclaration: dart:core::@class::int
''');
  }
}

@reflectiveTest
class ExtensionElementTest_augmentation_fromBytes
    extends ExtensionElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ExtensionElementTest_augmentation_keepLinking
    extends ExtensionElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class ExtensionElementTest_fromBytes extends ExtensionElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class ExtensionElementTest_keepLinking extends ExtensionElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
