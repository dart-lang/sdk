// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

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
      validator: (response) {
        // We have both `foo0x`, but no `bar`.
        check(response).suggestions.matchesInAnyOrder([
          (suggestion) => suggestion
            ..isImport
            ..completion.isEqualTo('package:foo/foo01.dart'),
          (suggestion) => suggestion
            ..isImport
            ..completion.isEqualTo('package:foo/foo02.dart'),
        ]);
      },
    );
  }

  Future<void> test_uri_notEnd() async {
    await _checkDirectives(
      uriContent: 'foo0^xyz',
      validator: (response) {
        // We ignore 'xyz' after the caret.
        check(response).suggestions.matchesInAnyOrder([
          (suggestion) => suggestion
            ..isImport
            ..completion.isEqualTo('package:foo/foo01.dart'),
          (suggestion) => suggestion
            ..isImport
            ..completion.isEqualTo('package:foo/foo02.dart'),
        ]);
      },
    );
  }

  Future<void> _checkDirectives({
    required String uriContent,
    required void Function(CompletionResponseForTesting response) validator,
  }) async {
    _configurePackagesFooBar();

    {
      var response = await getTestCodeSuggestions('''
export '$uriContent';
''');
      validator(response);
    }

    {
      var response = await getTestCodeSuggestions('''
import '$uriContent';
''');
      validator(response);
    }
  }

  void _configurePackagesFooBar() {
    final fooPackageRoot = getFolder('$packagesRootPath/foo');
    newFile('$packagesRootPath/foo/lib/foo01.dart', '');
    newFile('$packagesRootPath/foo/lib/foo02.dart', '');
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
