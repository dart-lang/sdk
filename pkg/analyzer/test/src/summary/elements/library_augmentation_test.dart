// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryAugmentationElementTest_keepLinking);
    defineReflectiveTests(LibraryAugmentationElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LibraryAugmentationElementTest extends ElementsBaseTest {
  test_augmentation_augmentationImports_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
class A {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
class B {}
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
class C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
      augmentationImports
        package:test/b.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
          reference: <testLibrary>::@augmentation::package:test/b.dart
          definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @31
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class A @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class B @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@class::B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
''');
  }

  test_augmentation_class_constructor_superConstructor_generic_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
class B extends A<int> {
  B() : super.named(0);
}
''');
    var library = await buildLibrary('''
import augment 'a.dart';
class A<T> {
  A.named(T a);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @31
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @33
              defaultType: dynamic
          constructors
            named @42
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 41
              nameEnd: 47
              parameters
                requiredPositional a @50
                  type: T
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class B @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          supertype: A<int>
          constructors
            @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::B
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::named
                substitution: {T: int}
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_augmentation_class_constructor_superConstructor_notGeneric_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
class B extends A {
  B() : super.named();
}
''');
    var library = await buildLibrary('''
import augment 'a.dart';
class A {
  A.named();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @31
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            named @39
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 38
              nameEnd: 44
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class B @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          supertype: A
          constructors
            @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::named
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_augmentation_class_constructor_superConstructor_notGeneric_unnamed_explicit() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
class B extends A {
  B() : super();
}
''');
    var library = await buildLibrary('''
import augment 'a.dart';
class A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @31
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class B @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          supertype: A
          constructors
            @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_augmentation_class_notSimplyBounded_circularity_via_typedef() async {
    // C's type parameter T is not simply bounded because its bound, F, expands
    // to `dynamic F(C)`, which refers to C.
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
class C<T extends F> {}
''');
    var library = await buildLibrary('''
import augment 'a.dart';
typedef F(C value);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased notSimplyBounded F @33
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function(C<dynamic>)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional value @37
                type: C<dynamic>
            returnType: dynamic
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        notSimplyBounded class C @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @37
              bound: dynamic
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_augmentation_class_notSimplyBounded_self() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
class C<T extends C> {}
''');
    var library = await buildLibrary('''
import augment 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        notSimplyBounded class C @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::C
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @37
              bound: C<dynamic>
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::C::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_augmentation_defaultValue_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const a = 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
void f({int x = A.a}) {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      functions
        f @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@function::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          parameters
            optionalNamed default x @58
              reference: <testLibrary>::@fragment::package:test/b.dart::@function::f::@parameter::x
              type: int
              constantInitializer
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: A @62
                    staticElement: package:test/a.dart::<fragment>::@class::A
                    staticType: null
                  period: . @63
                  identifier: SimpleIdentifier
                    token: a @64
                    staticElement: package:test/a.dart::<fragment>::@class::A::@getter::a
                    staticType: int
                  staticElement: package:test/a.dart::<fragment>::@class::A::@getter::a
                  staticType: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
''');
  }

  test_augmentation_defaultValue_prefix_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const a = 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart' as prefix;
void f({int x = prefix.A.a}) {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart as prefix @48
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      prefixes
        prefix @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
          enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix @48
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      libraryImportPrefixes
        prefix @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
          enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      functions
        f @61
          reference: <testLibrary>::@fragment::package:test/b.dart::@function::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          parameters
            optionalNamed default x @68
              reference: <testLibrary>::@fragment::package:test/b.dart::@function::f::@parameter::x
              type: int
              constantInitializer
                PropertyAccess
                  target: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: prefix @72
                      staticElement: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
                      staticType: null
                    period: . @78
                    identifier: SimpleIdentifier
                      token: A @79
                      staticElement: package:test/a.dart::<fragment>::@class::A
                      staticType: null
                    staticElement: package:test/a.dart::<fragment>::@class::A
                    staticType: null
                  operator: . @80
                  propertyName: SimpleIdentifier
                    token: a @81
                    staticElement: package:test/a.dart::<fragment>::@class::A::@getter::a
                    staticType: int
                  staticType: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
      prefixes
        prefix
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
''');
  }

  test_augmentation_importScope_constant() async {
    newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
const b = a;
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        static const b @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::b
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            SimpleIdentifier
              token: a @56
              staticElement: package:test/a.dart::<fragment>::@getter::a
              staticType: int
      accessors
        synthetic static get b @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::b
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
''');
  }

  test_augmentation_importScope_constant_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const a = 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
const b = A.a;
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        static const b @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::b
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PrefixedIdentifier
              prefix: SimpleIdentifier
                token: A @56
                staticElement: package:test/a.dart::<fragment>::@class::A
                staticType: null
              period: . @57
              identifier: SimpleIdentifier
                token: a @58
                staticElement: package:test/a.dart::<fragment>::@class::A::@getter::a
                staticType: int
              staticElement: package:test/a.dart::<fragment>::@class::A::@getter::a
              staticType: int
      accessors
        synthetic static get b @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::b
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
''');
  }

  test_augmentation_importScope_constant_instanceCreation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A {};
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
const a = A();
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        static const a @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::a
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: A
          shouldUseTypeForInitializerInference: false
          constantInitializer
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @56
                  element: package:test/a.dart::<fragment>::@class::A
                  type: A
                staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @57
                rightParenthesis: ) @58
              staticType: A
      accessors
        synthetic static get a @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::a
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
''');
  }

  test_augmentation_importScope_constant_prefix_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const a = 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart' as prefix;
const b = prefix.A.a;
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart as prefix @48
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      prefixes
        prefix @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
          enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix @48
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      libraryImportPrefixes
        prefix @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
          enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        static const b @62
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::b
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            PropertyAccess
              target: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: prefix @66
                  staticElement: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
                  staticType: null
                period: . @72
                identifier: SimpleIdentifier
                  token: A @73
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A
                staticType: null
              operator: . @74
              propertyName: SimpleIdentifier
                token: a @75
                staticElement: package:test/a.dart::<fragment>::@class::A::@getter::a
                staticType: int
              staticType: int
      accessors
        synthetic static get b @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::b
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
      prefixes
        prefix
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
''');
  }

  test_augmentation_importScope_prefixed_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart' as prefix;

@prefix.A()
void f() {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart as prefix @48
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      prefixes
        prefix @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
          enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix @48
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      libraryImportPrefixes
        prefix @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
          enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      functions
        f @74
          reference: <testLibrary>::@fragment::package:test/b.dart::@function::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          metadata
            Annotation
              atSign: @ @57
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: prefix @58
                  staticElement: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
                  staticType: null
                period: . @64
                identifier: SimpleIdentifier
                  token: A @65
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @66
                rightParenthesis: ) @67
              element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
      prefixes
        prefix
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
''');
  }

  test_augmentation_importScope_prefixed_typeAnnotation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart' as prefix;
prefix.A f() {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart as prefix @48
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      prefixes
        prefix @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
          enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix @48
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      libraryImportPrefixes
        prefix @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
          enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      functions
        f @65
          reference: <testLibrary>::@fragment::package:test/b.dart::@function::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
      prefixes
        prefix
          reference: <testLibrary>::@fragment::package:test/b.dart::@prefix::prefix
''');
  }

  test_augmentation_importScope_topInference() async {
    newFile('$testPackageLibPath/a.dart', r'''
final a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
final b = a;
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      topLevelVariables
        static final b @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@topLevelVariable::b
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get b @-1
          reference: <testLibrary>::@fragment::package:test/b.dart::@getter::b
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
''');
  }

  test_augmentation_importScope_types_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
A f() {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
A f() {}
''');

    // The augmentation imports `a.dart`, so can resolve `A`.
    // But the library does not import, so there `A` is unresolved.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @27
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      functions
        f @48
          reference: <testLibrary>::@fragment::package:test/b.dart::@function::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
''');
  }

  @SkippedTest(reason: r'''
We use library fragment scopes now.
And we will remove support for library augmentations.
We keep this test for now as a reference.
Later we will decide if we want to adapt it into enhanced parts. 
''')
  test_augmentation_importScope_types_library() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
A f() {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';
import 'a.dart';
A f() {}
''');

    // The library imports `a.dart`, so can resolve `A`.
    // But the augmentation does not import, so there `A` is unresolved.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      functions
        f @44
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      functions
        f @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@function::f
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
''');
  }

  test_augmentation_libraryExports_library() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
export 'dart:async';
''');
    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
export 'dart:collection';
export 'dart:math';
''');
    var library = await buildLibrary(r'''
import 'dart:io';
import augment 'a.dart';
import augment 'b.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:io
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      libraryExports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryExports
        dart:collection
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:io
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        dart:collection
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        dart:io
    <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
''');
  }

  test_augmentation_libraryImports_library() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import 'dart:async';
''');
    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'dart:collection';
import 'dart:math';
''');
    var library = await buildLibrary(r'''
import 'dart:io';
import augment 'a.dart';
import augment 'b.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:io
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      libraryImports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        dart:collection
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:io
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        dart:collection
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        dart:io
    <testLibrary>::@fragment::package:test/a.dart
      libraryImports
        dart:async
    <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        dart:collection
        dart:math
''');
  }

  test_augmentation_topScope_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
class A {}
A f() {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
A f() {}
''');

    // The augmentation declares `A`, and can it be used in the library.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @27
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::A
      functions
        f @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@function::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_augmentation_topScope_library() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
A f() {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
class A {}
A f() {}
''');

    // The library declares `A`, and can it be used in the augmentation.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @31
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      functions
        f @38
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      functions
        f @31
          reference: <testLibrary>::@fragment::package:test/a.dart::@function::f
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }
}

@reflectiveTest
class LibraryAugmentationElementTest_fromBytes
    extends LibraryAugmentationElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LibraryAugmentationElementTest_keepLinking
    extends LibraryAugmentationElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
