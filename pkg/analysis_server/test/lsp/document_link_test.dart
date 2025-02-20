// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentLinkTest);
  });
}

@reflectiveTest
class DocumentLinkTest extends AbstractLspAnalysisServerTest {
  Future<void> test_exampleLink() async {
    var exampleFolderPath = join(projectFolderPath, 'examples', 'api');
    var exampleFileUri = Uri.file(join(exampleFolderPath, 'foo.dart'));

    var code = TestCode.parse('''
/// {@tool dartpad}
/// ** See code in [!examples/api/foo.dart!] **
/// {@end-tool}
class A {}
''');

    newFolder(exampleFolderPath);
    newFile(mainFilePath, code.code);

    await initialize();
    var links = await getDocumentLinks(mainFileUri);

    var link = links!.single;
    expect(link.range, code.range.range);
    expect(link.target, exampleFileUri);
  }

  Future<void> test_pubspec_empty() async {
    var content = '';

    await _test_pubspec_links(content, isEmpty);
  }

  Future<void> test_pubspec_packages_empty() async {
    var content = '''
dependencies:
''';

    await _test_pubspec_links(content, isEmpty);
  }

  Future<void> test_pubspec_packages_git() async {
    var content = '''
dependencies:
  github_package_1:
    git: https://github.com/dart-lang/sdk.git
  github_package_2:
    git: git@github.com:dart-lang/sdk.git
  github_package_3:
    git:
      url: https://github.com/dart-lang/sdk.git
''';

    var expectedLinks = {
      'github_package_1': 'https://github.com/dart-lang/sdk.git',
      'github_package_2': 'https://github.com/dart-lang/sdk.git',
      'github_package_3': 'https://github.com/dart-lang/sdk.git',
    };

    await _test_pubspec_links(content, equals(expectedLinks));
  }

  Future<void> test_pubspec_packages_hosted() async {
    var content = '''
dependencies:
  hosted_package_1:
    hosted: https://custom.dart.dev/
  hosted_package_2:
    hosted:
      url: https://custom.dart.dev/
''';

    var expectedLinks = {
      'hosted_package_1': 'https://custom.dart.dev/packages/hosted_package_1',
      'hosted_package_2': 'https://custom.dart.dev/packages/hosted_package_2',
    };

    await _test_pubspec_links(content, equals(expectedLinks));
  }

  Future<void> test_pubspec_packages_pub() async {
    var content = '''
dependencies:
  pub_package_1: 1.2.3
  pub_package_2: ^1.2.3
  pub_package_3:
  pub_package_4: any
''';

    var expectedLinks = {
      'pub_package_1': 'https://pub.dev/packages/pub_package_1',
      'pub_package_2': 'https://pub.dev/packages/pub_package_2',
      'pub_package_3': 'https://pub.dev/packages/pub_package_3',
      'pub_package_4': 'https://pub.dev/packages/pub_package_4',
    };

    await _test_pubspec_links(content, equals(expectedLinks));
  }

  Future<void> test_pubspec_packages_unknown() async {
    var content = '''
dependencies:
  flutter:
    sdk: flutter
  foo:
    path: foo/
  bar:
    future_unknown_kind:
''';

    await _test_pubspec_links(content, isEmpty);
  }

  Future<void> test_pubspec_packages_withDevDependencies() async {
    var content = '''
dependencies:
  dep_package: 1.2.3

dev_dependencies:
  dev_dep_package:
''';

    var expectedLinks = {
      'dep_package': 'https://pub.dev/packages/dep_package',
      'dev_dep_package': 'https://pub.dev/packages/dev_dep_package',
    };

    await _test_pubspec_links(content, equals(expectedLinks));
  }

  Future<void> _test_pubspec_links(String content, Matcher expected) async {
    newFile(pubspecFilePath, content);

    await initialize();
    var links = await getDocumentLinks(pubspecFileUri);

    // Build a map of the links and their text from the document for easy
    // comparison.
    var linkMap = {
      for (var link in links!)
        getTextForRange(content, link.range): link.target?.toString(),
    };

    expect(linkMap, expected);
  }
}
