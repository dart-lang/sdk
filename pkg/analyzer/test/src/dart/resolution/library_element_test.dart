// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryElementTest);
  });
}

@reflectiveTest
class LibraryElementTest extends DriverResolutionTest {
  test_languageVersion() async {
    newFile('/test/.dart_tool/package_config.json', content: '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    },
    {
      "name": "aaa",
      "rootUri": "${toUriStr('/aaa')}",
      "packageUri": "lib/"
    }
  ]
}
''');
    driver.configure(
      packages: findPackagesFrom(
        resourceProvider,
        getFolder('/test'),
      ),
    );

    newFile('/test/lib/a.dart', content: r'''
class A {}
''');

    newFile('/test/lib/b.dart', content: r'''
// @dart = 2.6
class A {}
''');

    newFile('/test/lib/c.dart', content: r'''
// @dart = 2.9
class A {}
''');

    newFile('/test/lib/d.dart', content: r'''
// @dart = 2.99
class A {}
''');

    newFile('/test/lib/e.dart', content: r'''
// @dart = 3.0
class A {}
''');

    newFile('/aaa/lib/a.dart', content: r'''
class A {}
''');

    newFile('/aaa/lib/b.dart', content: r'''
// @dart = 2.99
class A {}
''');

    newFile('/aaa/lib/c.dart', content: r'''
// @dart = 3.0
class A {}
''');

    // No override.
    await _assertLanguageVersion('package:test/a.dart', 2, 7);

    // Valid override, less than the latest supported language version.
    await _assertLanguageVersion('package:test/b.dart', 2, 6);

    // Valid override, even if greater than the package language version.
    await _assertLanguageVersion('package:test/c.dart', 2, 9);

    // Invalid override: minor is greater than the latest minor.
    await _assertLanguageVersion('package:test/d.dart', 2, 7);

    // Invalid override: major is greater than the latest major.
    await _assertLanguageVersion('package:test/e.dart', 2, 7);

    await _assertLanguageVersionCurrent('package:aaa/a.dart');
    await _assertLanguageVersionCurrent('package:aaa/b.dart');
    await _assertLanguageVersionCurrent('package:aaa/c.dart');
  }

  Future<void> _assertLanguageVersion(
    String uriStr,
    int major,
    int minor,
  ) async {
    var element = await driver.getLibraryByUri(uriStr);
    expect(element.languageVersionMajor, major);
    expect(element.languageVersionMinor, minor);
  }

  Future<void> _assertLanguageVersionCurrent(String uriStr) async {
    await _assertLanguageVersion(
      uriStr,
      ExperimentStatus.currentVersion.major,
      ExperimentStatus.currentVersion.minor,
    );
  }
}
