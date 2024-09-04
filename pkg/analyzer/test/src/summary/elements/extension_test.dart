// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_extension_documented_tripleSlash() async {
    var library = await buildLibrary('''
/// aaa
/// bbbb
/// cc
extension E on int {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensions
        E @34
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          documentationComment: /// aaa\n/// bbbb\n/// cc
          extendedType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensions
        extension E @34
          reference: <testLibraryFragment>::@extension::E
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
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
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
          fields
            x @36
              reference: <testLibraryFragment>::@extension::E::@field::x
              enclosingFragment: <testLibraryFragment>::@extension::E
          getters
            get x @-1
              reference: <testLibraryFragment>::@extension::E::@getter::x
              enclosingFragment: <testLibraryFragment>::@extension::E
''');
  }

  test_extension_typeParameters_hasBound() async {
    var library = await buildLibrary('''
extension E<T extends num> on int {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @12
              bound: num
              defaultType: num
          extendedType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
''');
  }

  test_extension_typeParameters_noBound() async {
    var library = await buildLibrary('''
extension E<T> on int {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @12
              defaultType: dynamic
          extendedType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
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
          extendedType: int
          fields
            static const foo @65
              reference: <testLibraryFragment>::@extension::E::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::E
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 1 @71
                  staticType: int
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::E::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::E
              returnType: int
          methods
            bar @88
              reference: <testLibraryFragment>::@extension::E::@method::bar
              enclosingElement: <testLibraryFragment>::@extension::E
              metadata
                Annotation
                  atSign: @ @76
                  name: SimpleIdentifier
                    token: foo @77
                    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@extension::E::@getter::foo
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
      extensions
        extension E @31
          reference: <testLibraryFragment>::@extension::E
          fields
            foo @65
              reference: <testLibraryFragment>::@extension::E::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::E
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::E::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::E
          methods
            bar @88
              reference: <testLibraryFragment>::@extension::E::@method::bar
              enclosingFragment: <testLibraryFragment>::@extension::E
              metadata
                Annotation
                  atSign: @ @76
                  name: SimpleIdentifier
                    token: foo @77
                    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@extension::E::@getter::foo
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
      extensions
        E @50
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @27
              name: SimpleIdentifier
                token: a @28
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: Object @31
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @37
                rightParenthesis: ) @38
              element: dart:core::<fragment>::@class::Object::@constructor::new
          extendedType: A
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
      classes
        class A @22
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
      extensions
        extension E @50
          reference: <testLibraryFragment>::@extension::E
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          extendedType: int
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@extension::E::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::E
              type: int
              nonSynthetic: <testLibraryFragment>::@extension::E::@getter::foo
          accessors
            get foo @31
              reference: <testLibraryFragment>::@extension::E::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::E
              returnType: int
              nonSynthetic: <testLibraryFragment>::@extension::E::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
          fields
            foo @-1
              reference: <testLibraryFragment>::@extension::E::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::E
          getters
            get foo @31
              reference: <testLibraryFragment>::@extension::E::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::E
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E
          enclosingElement: <testLibraryFragment>
          extendedType: int
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@extension::E::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::E
              type: int
              nonSynthetic: <testLibraryFragment>::@extension::E::@setter::foo
          accessors
            set foo= @27
              reference: <testLibraryFragment>::@extension::E::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::E
              parameters
                requiredPositional value @35
                  type: int
                  nonSynthetic: <testLibraryFragment>::@extension::E::@setter::foo::@parameter::value
              returnType: void
              nonSynthetic: <testLibraryFragment>::@extension::E::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
          fields
            foo @-1
              reference: <testLibraryFragment>::@extension::E::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::E
          setters
            set foo= @27
              reference: <testLibraryFragment>::@extension::E::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::E
''');
  }
}

abstract class ExtensionElementTest_augmentation extends ElementsBaseTest {
  test_augmentationTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment extension A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment extension A {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {}
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          augmented
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensions
        augment A @54
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensions
        augment A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
  exportedReferences
    declared <testLibraryFragment>::@extension::A
  exportNamespace
    A: <testLibraryFragment>::@extension::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensions
        extension A @54
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
  exportedReferences
    declared <testLibraryFragment>::@extension::A
  exportNamespace
    A: <testLibraryFragment>::@extension::A
''');
  }

  test_augmentationTarget_no2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment extension A {
  void foo1() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment extension A {
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
      extensions
        augment A @54
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          extendedType: InvalidType
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          methods
            foo1 @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: void
          augmented
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::foo1
              <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@method::foo2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensions
        augment A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo2 @47
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@method::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensions
        extension A @54
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          methods
            foo1 @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::foo1
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo2 @47
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@method::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
''');
  }

  test_augmented_field_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int foo = 1;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo @49
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo
              <testLibraryFragment>::@extension::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          fields
            augment static foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@extension::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @49
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          fields
            foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@field::foo
''');
  }

  test_augmented_field_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int foo = 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension A on int {
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
      extensions
        A @40
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo @64
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo
              <testLibraryFragment>::@extension::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          fields
            augment static foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@extension::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            augment static foo @64
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @40
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @64
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          fields
            foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@field::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @64
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int get foo => 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension A on int {
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
      extensions
        A @40
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo @64
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extension::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          accessors
            augment static get foo @68
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@extension::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            augment static foo @64
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@extension::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @40
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @64
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          getters
            augment get foo @68
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @64
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static set foo(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension A on int {
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
      extensions
        A @40
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo @64
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          accessors
            augment static set foo= @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              parameters
                requiredPositional _ @72
                  type: int
              returnType: void
              id: setter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@extension::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            augment static foo @64
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@extension::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @40
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @64
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          setters
            augment set foo= @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @64
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@field::foo
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static double foo = 1.2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo @49
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo
              <testLibraryFragment>::@extension::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          fields
            augment static foo @67
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              type: double
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@extension::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @49
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          fields
            foo @67
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@field::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int foo = 1;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            synthetic static foo @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              id: field_0
              getter: getter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          accessors
            static get foo @53
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          fields
            augment static foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@extension::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
          getters
            get foo @53
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          fields
            foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@fieldAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@field::foo
''');
  }

  test_augmented_fields_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  static int foo2 = 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo1 @49
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic static get foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static set foo1= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo1 @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo1
              <testLibraryFragment>::@extension::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          fields
            static foo2 @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_1
          accessors
            synthetic static get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic static set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              parameters
                requiredPositional _foo2 @-1
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo1 @49
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
          getters
            get foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
          setters
            set foo1= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          fields
            foo2 @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          getters
            get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          setters
            set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setter::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_getters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  int get foo2 => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              id: field_0
              getter: getter_0
          accessors
            get foo1 @46
              reference: <testLibraryFragment>::@extension::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              type: int
              id: field_1
              getter: getter_1
          accessors
            get foo2 @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: int
              id: getter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
          getters
            get foo1 @46
              reference: <testLibraryFragment>::@extension::A::@getter::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          getters
            get foo2 @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A<T2> {
  T2 get foo2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A<T1> on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @27
              defaultType: dynamic
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              type: T1
              id: field_0
              getter: getter_0
          accessors
            abstract get foo1 @49
              reference: <testLibraryFragment>::@extension::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: T1
              id: getter_0
              variable: field_0
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
                augmentationSubstitution: {T2: T1}
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo1
              PropertyAccessorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
                augmentationSubstitution: {T2: T1}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @41
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extension::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              type: T2
              id: field_1
              getter: getter_1
          accessors
            abstract get foo2 @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: T2
              id: getter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
          getters
            get foo1 @49
              reference: <testLibraryFragment>::@extension::A::@getter::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          getters
            get foo2 @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getter::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_getters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo @49
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extension::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          accessors
            augment static get foo @68
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@extension::A::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @49
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          getters
            augment get foo @68
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@getter::foo
''');
  }

  test_augmented_getters_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension A {
  augment static int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension A on int {
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
      extensions
        A @40
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo @64
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@extension::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          accessors
            augment static get foo @68
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@extension::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          accessors
            augment static get foo @68
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @40
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @64
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          getters
            augment get foo @68
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          getters
            augment get foo @68
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
''');
  }

  test_augmented_getters_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment int get foo1 => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              id: field_1
              getter: getter_1
          accessors
            get foo1 @46
              reference: <testLibraryFragment>::@extension::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo1
            get foo2 @67
              reference: <testLibraryFragment>::@extension::A::@getter::foo2
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo1
              <testLibraryFragment>::@extension::A::@field::foo2
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo1
              <testLibraryFragment>::@extension::A::@getter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          accessors
            augment get foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@extension::A::@getter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
            foo2 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo2
              enclosingFragment: <testLibraryFragment>::@extension::A
          getters
            get foo1 @46
              reference: <testLibraryFragment>::@extension::A::@getter::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo1
            get foo2 @67
              reference: <testLibraryFragment>::@extension::A::@getter::foo2
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          getters
            augment get foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo1
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@getter::foo1
''');
  }

  test_augmented_getters_augment_getter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment extension A {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
extension A on int {
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
      extensions
        A @40
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              id: field_0
              getter: getter_0
          accessors
            get foo @61
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          accessors
            augment get foo @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@extension::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          accessors
            augment get foo @61
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @40
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          getters
            get foo @61
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          getters
            augment get foo @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          getters
            augment get foo @61
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@getterAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@getterAugmentation::foo
''');
  }

  test_augmented_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: void
          augmented
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::bar
              <testLibraryFragment>::@extension::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          methods
            bar @50
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          methods
            bar @50
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::bar
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_methods_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment void foo1() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo1 @43
              reference: <testLibraryFragment>::@extension::A::@method::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo1
            foo2 @60
              reference: <testLibraryFragment>::@extension::A::@method::foo2
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: void
          augmented
            methods
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo1
              <testLibraryFragment>::@extension::A::@method::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          methods
            augment foo1 @58
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extension::A::@method::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo1 @43
              reference: <testLibraryFragment>::@extension::A::@method::foo1
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
            foo2 @60
              reference: <testLibraryFragment>::@extension::A::@method::foo2
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          methods
            augment foo1 @58
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo1
              previousFragment: <testLibraryFragment>::@extension::A::@method::foo1
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_methods_augment2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment extension A {
  augment void foo() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment extension A {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
          augmented
            methods
              <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      extensions
        augment A @54
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          methods
            augment foo @73
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extension::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      extensions
        augment A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            augment foo @55
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      extensions
        extension A @54
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          methods
            augment foo @73
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              previousFragment: <testLibraryFragment>::@extension::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            augment foo @55
              reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A::@methodAugmentation::foo
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
''');
  }

  test_augmented_methods_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A<T2> {
  T2 bar() => throw 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A<T> on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @27
              defaultType: dynamic
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: T
          augmented
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::bar
                augmentationSubstitution: {T2: T}
              <testLibraryFragment>::@extension::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @41
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extension::A
          methods
            bar @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: T2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          methods
            bar @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@method::bar
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_methods_generic_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A<T2> {
  augment T2 foo() => throw 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A<T> on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @27
              defaultType: dynamic
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: T
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
          augmented
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T2: T}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @41
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extension::A
          methods
            augment foo @60
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: T2
              augmentationTarget: <testLibraryFragment>::@extension::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          methods
            augment foo @60
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              previousFragment: <testLibraryFragment>::@extension::A::@method::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_methods_typeParameterCountMismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A<T> {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
            bar @59
              reference: <testLibraryFragment>::@extension::A::@method::bar
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: void
          augmented
            methods
              <testLibraryFragment>::@extension::A::@method::bar
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T: InvalidType}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @41
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@extension::A
          methods
            augment foo @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@extension::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          methods
            foo @43
              reference: <testLibraryFragment>::@extension::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
            bar @59
              reference: <testLibraryFragment>::@extension::A::@method::bar
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          methods
            augment foo @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@methodAugmentation::foo
              previousFragment: <testLibraryFragment>::@extension::A::@method::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_setters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  set foo2(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              id: field_0
              setter: setter_0
          accessors
            set foo1= @42
              reference: <testLibraryFragment>::@extension::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _ @51
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
            accessors
              <testLibraryFragment>::@extension::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              type: int
              id: field_1
              setter: setter_1
          accessors
            set foo2= @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              parameters
                requiredPositional _ @58
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
          setters
            set foo1= @42
              reference: <testLibraryFragment>::@extension::A::@setter::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@field::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          setters
            set foo2= @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setter::foo2
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
''');
  }

  test_augmented_setters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment static set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            static foo @49
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic static set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo
            accessors
              <testLibraryFragment>::@extension::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          accessors
            augment static set foo= @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              parameters
                requiredPositional _ @72
                  type: int
              returnType: void
              id: setter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@extension::A::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo @49
              reference: <testLibraryFragment>::@extension::A::@field::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          getters
            get foo @-1
              reference: <testLibraryFragment>::@extension::A::@getter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@extension::A::@setter::foo
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          setters
            augment set foo= @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@setter::foo
''');
  }

  test_augmented_setters_augment_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment extension A {
  augment set foo1(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension A on int {
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
      extensions
        A @25
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              id: field_0
              setter: setter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@extension::A
              type: int
              id: field_1
              setter: setter_1
          accessors
            set foo1= @42
              reference: <testLibraryFragment>::@extension::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _ @51
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo1
            set foo2= @63
              reference: <testLibraryFragment>::@extension::A::@setter::foo2
              enclosingElement: <testLibraryFragment>::@extension::A
              parameters
                requiredPositional _ @72
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@extension::A::@field::foo1
              <testLibraryFragment>::@extension::A::@field::foo2
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo1
              <testLibraryFragment>::@extension::A::@setter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
          accessors
            augment set foo1= @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              parameters
                requiredPositional _ @66
                  type: int
              returnType: void
              id: setter_2
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@extension::A::@setter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @25
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
            foo2 @-1
              reference: <testLibraryFragment>::@extension::A::@field::foo2
              enclosingFragment: <testLibraryFragment>::@extension::A
          setters
            set foo1= @42
              reference: <testLibraryFragment>::@extension::A::@setter::foo1
              enclosingFragment: <testLibraryFragment>::@extension::A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo1
            set foo2= @63
              reference: <testLibraryFragment>::@extension::A::@setter::foo2
              enclosingFragment: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      extensions
        extension A @39
          reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
          setters
            augment set foo1= @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A::@setterAugmentation::foo1
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::A
              previousFragment: <testLibraryFragment>::@extension::A::@setter::foo1
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

extension A on int {}
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
      extensions
        A @41
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibraryFragment>::@extension::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @41
          reference: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    class A
      reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
''');
  }

  test_augmentedBy_class_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment extension A {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';

extension A on int {}
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
      extensions
        A @41
          reference: <testLibraryFragment>::@extension::A
          enclosingElement: <testLibraryFragment>
          extendedType: int
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          augmented
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@extension::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      extensions
        augment A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@extension::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @41
          reference: <testLibraryFragment>::@extension::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      extensions
        extension A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@extensionAugmentation::A
          previousFragment: <testLibraryFragment>::@extension::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
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
