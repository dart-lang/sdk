// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportResolutionTest);
  });
}

@reflectiveTest
class ExportResolutionTest extends DriverResolutionTest {
  test_configurations_default() async {
    newFile('/test/lib/a.dart', content: 'class A {}');
    newFile('/test/lib/a_html.dart', content: 'class A {}');
    newFile('/test/lib/a_io.dart', content: 'class A {}');

    _setDeclaredVariables({
      'dart.library.html': 'false',
      'dart.library.io': 'false',
    });

    await assertNoErrorsInCode(r'''
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    assertNamespaceDirectiveSelected(
      findNode.export('a.dart'),
      expectedRelativeUri: 'a.dart',
      expectedUri: 'package:test/a.dart',
    );

    assertElementLibraryUri(
      result.libraryElement.exportNamespace.get('A'),
      'package:test/a.dart',
    );
  }

  test_configurations_first() async {
    newFile('/test/lib/a.dart', content: 'class A {}');
    newFile('/test/lib/a_html.dart', content: 'class A {}');
    newFile('/test/lib/a_io.dart', content: 'class A {}');

    _setDeclaredVariables({
      'dart.library.html': 'true',
      'dart.library.io': 'false',
    });

    await assertNoErrorsInCode(r'''
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    assertNamespaceDirectiveSelected(
      findNode.export('a.dart'),
      expectedRelativeUri: 'a_html.dart',
      expectedUri: 'package:test/a_html.dart',
    );

    assertElementLibraryUri(
      result.libraryElement.exportNamespace.get('A'),
      'package:test/a_html.dart',
    );
  }

  test_configurations_second() async {
    newFile('/test/lib/a.dart', content: 'class A {}');
    newFile('/test/lib/a_html.dart', content: 'class A {}');
    newFile('/test/lib/a_io.dart', content: 'class A {}');

    _setDeclaredVariables({
      'dart.library.html': 'false',
      'dart.library.io': 'true',
    });

    await assertNoErrorsInCode(r'''
export 'a.dart'
  if (dart.library.html) 'a_html.dart'
  if (dart.library.io) 'a_io.dart';
''');

    assertNamespaceDirectiveSelected(
      findNode.export('a.dart'),
      expectedRelativeUri: 'a_io.dart',
      expectedUri: 'package:test/a_io.dart',
    );

    assertElementLibraryUri(
      result.libraryElement.exportNamespace.get('A'),
      'package:test/a_io.dart',
    );
  }

  /// Test that both getter and setter are in the export namespace.
  test_namespace_getter_setter() async {
    newFile('/test/lib/a.dart', content: r'''
get f => null;
set f(_) {}
''');
    await resolveTestCode(r'''
export 'a.dart';
''');
    var exportNamespace = result.libraryElement.exportNamespace;
    expect(exportNamespace.get('f'), isNotNull);
    expect(exportNamespace.get('f='), isNotNull);
  }

  void _setDeclaredVariables(Map<String, String> map) {
    driver.declaredVariables = DeclaredVariables.fromMap(map);
    driver.configure();
  }
}
