// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
}
