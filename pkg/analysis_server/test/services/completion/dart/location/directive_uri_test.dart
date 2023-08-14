// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DirectiveUriTest);
  });
}

@reflectiveTest
class DirectiveUriTest extends AbstractCompletionDriverTest {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;

  Future<void> test_uri_end() async {
    await _checkDirectives(
      uriContent: 'foo0^',
      validator: () {
        // We have both `foo0x`, but no `bar`.
        assertResponse(r'''
replacement
  left: 4
suggestions
  package:foo/foo01.dart
    kind: import
  package:foo/foo02.dart
    kind: import
''');
      },
    );
  }

  Future<void> test_uri_notEnd() async {
    await _checkDirectives(
      uriContent: 'foo0^xyz',
      validator: () {
        // We ignore 'xyz' after the caret.
        assertResponse(r'''
replacement
  left: 4
  right: 3
suggestions
  package:foo/foo01.dart
    kind: import
  package:foo/foo02.dart
    kind: import
''');
      },
    );
  }

  Future<void> _checkDirectives({
    required String uriContent,
    required void Function() validator,
  }) async {
    _configurePackagesFooBar();
    await pumpEventQueue(times: 5000);

    {
      await computeSuggestions('''
export '$uriContent';
''');
      validator();
    }

    {
      await computeSuggestions('''
import '$uriContent';
''');
      validator();
    }
  }

  void _configurePackagesFooBar() {
    final fooPackageRoot = getFolder('$packagesRootPath/foo');
    newFile('$packagesRootPath/foo/lib/foo01.dart', '');
    newFile('$packagesRootPath/foo/lib/foo02.dart', '');
    // Files that are not `*.dart` should not be suggested.
    newFile('$packagesRootPath/foo/lib/foo03.txt', '');
    // We use this file to check that exactly `foo0` is used as prefix.
    // So, we don't have one-off and don't use just `foo`.
    newFile('$packagesRootPath/foo/lib/foo11.dart', '');

    final barPackageRoot = getFolder('$packagesRootPath/bar');
    newFile('$packagesRootPath/bar/lib/bar01.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: fooPackageRoot.path)
        ..add(name: 'bar', rootPath: barPackageRoot.path),
    );
  }
}
