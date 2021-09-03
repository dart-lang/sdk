// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsPackagesIntegrationTest);
  });
}

@reflectiveTest
class OptionsPackagesIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  @override
  Future startServer({int? diagnosticPort, int? servicesPort}) {
    var fooPath = sourcePath('foo');
    writeFile(
      path.join(fooPath, 'lib', 'foo.dart'),
      'var my_foo = 0;',
    );

    var packagesPath = sourcePath('my_packages.json');
    writeFile(packagesPath, '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "foo",
      "rootUri": "${path.toUri(fooPath)}",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''');

    return server.start(
      diagnosticPort: diagnosticPort,
      servicesPort: servicesPort,
      packagesFile: packagesPath,
    );
  }

  Future<void> test_it() {
    var pathname = sourcePath('test.dart');
    writeFile(pathname, '''
import 'package:foo/foo.dart';
void main() {
  my_foo;
}
''');
    standardAnalysisSetup();
    return analysisFinished.then((_) {
      var errors = existingErrorsForFile(pathname);
      expect(errors, isEmpty);
    });
  }
}
