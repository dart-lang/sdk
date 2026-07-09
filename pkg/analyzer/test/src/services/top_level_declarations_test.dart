// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/services/top_level_declarations.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelDeclarationsTest);
  });
}

@reflectiveTest
class TopLevelDeclarationsTest extends PubPackageResolutionTest {
  /// Verifies that the located public export for [element] is the library with
  /// URI [libraryUri].
  Future<void> expectPublicExport(
    TestResolvedUnitResult result,
    Element element,
    String libraryUri,
  ) async {
    var publicLibrary = await TopLevelDeclarations(
      result.analysisResult,
    ).publiclyExporting(element);
    expect(publicLibrary?.firstFragment.source.uri.toString(), libraryUri);
  }

  test_publiclyExporting_getter() async {
    var result = await resolveFileCode(
      '$testPackageLibPath/src/x.dart',
      "var x = 1;",
    );
    newFile('$testPackageLibPath/x.dart', "export 'src/x.dart';");

    var element = result.findElement.topGet('x');
    await expectPublicExport(result, element, 'package:test/x.dart');
  }

  test_publiclyExporting_lib() async {
    var result = await resolveFileCode(
      '$testPackageLibPath/x.dart',
      "class X {}",
    );

    var element = result.findElement.class_('X');
    await expectPublicExport(result, element, 'package:test/x.dart');
  }

  /// Verify we pick a library with the correct element and not just an element
  /// of the same name.
  test_publiclyExporting_matchingElement() async {
    // Create a class x in src and some public files where the middle one
    // exports X and the others declare their own elements with the same name.
    var result = await resolveFileCode(
      '$testPackageLibPath/src/x.dart',
      "class X {}",
    );
    newFile('$testPackageLibPath/x1.dart', "class X {}");
    newFile('$testPackageLibPath/x2.dart', "export 'src/x.dart';");
    newFile('$testPackageLibPath/x3.dart', "class X {}");

    var element = result.findElement.class_('X');
    await expectPublicExport(result, element, 'package:test/x2.dart');
  }

  test_publiclyExporting_setter() async {
    var result = await resolveFileCode(
      '$testPackageLibPath/src/x.dart',
      "var x = 1;",
    );
    newFile('$testPackageLibPath/x.dart', "export 'src/x.dart';");

    var element = result.findElement.topSet('x');
    await expectPublicExport(result, element, 'package:test/x.dart');
  }

  test_publiclyExporting_src() async {
    var result = await resolveFileCode(
      '$testPackageLibPath/src/x.dart',
      "class X {}",
    );
    newFile('$testPackageLibPath/x.dart', "export 'src/x.dart';");

    var element = result.findElement.class_('X');
    await expectPublicExport(result, element, 'package:test/x.dart');
  }
}
