// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryAugmentationImportElementTest_keepLinking);
    defineReflectiveTests(LibraryAugmentationImportElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LibraryAugmentationImportElementTest extends ElementsBaseTest {
  test_library_augmentationImports_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
class A {}
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
class B {}
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
        class B @31
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');

    var import_0 = library.augmentationImports[0];
    var augmentation = import_0.importedAugmentation!;
    expect(augmentation.enclosingElement, same(library));
  }

  test_library_augmentationImports_depthFirst() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
augment library 'test.dart';
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'c.dart';
''');

    configuration.withLibraryAugmentations = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentations
    <testLibrary>::@augmentation::package:test/a.dart
    <testLibrary>::@augmentation::package:test/b.dart
    <testLibrary>::@augmentation::package:test/c.dart
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
    package:test/c.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/c.dart
      definingUnit: <testLibrary>::@fragment::package:test/c.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/c.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/c.dart
      enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/c.dart
''');

    var import_0 = library.augmentationImports[0];
    var augmentation = import_0.importedAugmentation!;
    expect(augmentation.enclosingElement, same(library));
  }

  test_library_augmentationImports_noRelativeUriStr() async {
    var library = await buildLibrary(r'''
import augment '${'foo'}.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    noRelativeUriString
      enclosingElement: <testLibrary>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_augmentationImports_withRelativeUri_emptyUriSelf() async {
    var library = await buildLibrary(r'''
import augment '';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    source 'package:test/test.dart'
      enclosingElement: <testLibrary>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_augmentationImports_withRelativeUri_noSource() async {
    var library = await buildLibrary(r'''
import augment 'foo:bar';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    relativeUri 'foo:bar'
      enclosingElement: <testLibrary>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_augmentationImports_withRelativeUri_notAugmentation_library() async {
    newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    source 'package:test/a.dart'
      enclosingElement: <testLibrary>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_augmentationImports_withRelativeUri_notAugmentation_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of other.lib;
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    source 'package:test/a.dart'
      enclosingElement: <testLibrary>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_augmentationImports_withRelativeUri_notExists() async {
    var library = await buildLibrary(r'''
import augment 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    source 'package:test/a.dart'
      enclosingElement: <testLibrary>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_augmentationImports_withRelativeUriString() async {
    var library = await buildLibrary(r'''
import augment ':';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    relativeUriString ':'
      enclosingElement: <testLibrary>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }
}

@reflectiveTest
class LibraryAugmentationImportElementTest_fromBytes
    extends LibraryAugmentationImportElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LibraryAugmentationImportElementTest_keepLinking
    extends LibraryAugmentationImportElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
