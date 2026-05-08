// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/rules.dart';
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
  static const _pubBase = 'https://pub.dev/packages/';
  static const _lintBase = 'https://dart.dev/tools/linter-rules/';

  @override
  void setUp() {
    registerLintRules();
    super.setUp();
  }

  Future<void> test_analysisOptions_empty() async {
    var content = '';

    await _test_analysisOptions_links(content, []);
  }

  Future<void> test_analysisOptions_lint_links_list() async {
    var content = '''
linter:
  rules:
    - /*[0*/prefer_relative_imports/*0]*/
    - /*[1*/prefer_single_quotes/*1]*/
    - /*[2*/prefer_int_literals/*2]*/
    - /*[3*/no_runtimeType_toString/*3]*/
''';

    var expectedLinks = [
      '${_lintBase}prefer_relative_imports',
      '${_lintBase}prefer_single_quotes',
      '${_lintBase}prefer_int_literals',
      '${_lintBase}no_runtimetype_tostring',
    ];

    await _test_analysisOptions_links(content, expectedLinks);
  }

  Future<void> test_analysisOptions_lint_links_map() async {
    var content = '''
linter:
  rules:
    /*[0*/prefer_relative_imports/*0]*/: true
    /*[1*/prefer_single_quotes/*1]*/: true
    /*[2*/prefer_int_literals/*2]*/: false
''';

    var expectedLinks = [
      '${_lintBase}prefer_relative_imports',
      '${_lintBase}prefer_single_quotes',
      '${_lintBase}prefer_int_literals',
    ];

    await _test_analysisOptions_links(content, expectedLinks);
  }

  Future<void> test_analysisOptions_linterRules_empty() async {
    var content = '''
linter:
  rules:
''';

    await _test_pubspec_links(content, []);
  }

  Future<void> test_analysisOptions_plugins_and_lints() async {
    var content = '''
analyzer:
  plugins:
    - /*[0*/my_plugin/*0]*/

linter:
  rules:
    - /*[1*/await_only_futures/*1]*/
''';

    var expectedLinks = [
      '${_pubBase}my_plugin',
      '${_lintBase}await_only_futures',
    ];

    await _test_analysisOptions_links(content, expectedLinks);
  }

  Future<void> test_analysisOptions_plugins_list() async {
    var content = '''
analyzer:
  plugins:
    - /*[0*/dart_code_metrics/*0]*/
    - /*[1*/custom_lint/*1]*/
''';

    var expectedLinks = [
      '${_pubBase}dart_code_metrics',
      '${_pubBase}custom_lint',
    ];

    await _test_analysisOptions_links(content, expectedLinks);
  }

  Future<void> test_analysisOptions_plugins_map() async {
    var content = '''
analyzer:
  plugins:
    /*[0*/dart_code_metrics/*0]*/:
      enabled: true
    /*[1*/custom_lint/*1]*/:
      options:
        foo: bar
''';

    var expectedLinks = [
      '${_pubBase}dart_code_metrics',
      '${_pubBase}custom_lint',
    ];

    await _test_analysisOptions_links(content, expectedLinks);
  }

  Future<void> test_analysisOptions_undefinedLint() async {
    var content = '''
linter:
  rules:
    - undefined
    - /*[0*/prefer_single_quotes/*0]*/
''';

    var expectedLinks = ['${_lintBase}prefer_single_quotes'];

    await _test_analysisOptions_links(content, expectedLinks);
  }

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

    await _test_pubspec_links(content, []);
  }

  Future<void> test_pubspec_packages_empty() async {
    var content = '''
dependencies:
''';

    await _test_pubspec_links(content, []);
  }

  Future<void> test_pubspec_packages_git() async {
    var content = '''
dependencies:
  /*[0*/github_package_1/*0]*/:
    git: https://github.com/dart-lang/sdk.git
  /*[1*/github_package_2/*1]*/:
    git: git@github.com:dart-lang/sdk.git
  /*[2*/github_package_3/*2]*/:
    git:
      url: https://github.com/dart-lang/sdk.git
''';

    var expectedLinks = [
      'https://github.com/dart-lang/sdk.git',
      'https://github.com/dart-lang/sdk.git',
      'https://github.com/dart-lang/sdk.git',
    ];

    await _test_pubspec_links(content, expectedLinks);
  }

  Future<void> test_pubspec_packages_hosted() async {
    var content = '''
dependencies:
  /*[0*/hosted_package_1/*0]*/:
    hosted: https://custom.dart.dev/
  /*[1*/hosted_package_2/*1]*/:
    hosted:
      url: https://custom.dart.dev/
''';

    var expectedLinks = [
      'https://custom.dart.dev/packages/hosted_package_1',
      'https://custom.dart.dev/packages/hosted_package_2',
    ];

    await _test_pubspec_links(content, expectedLinks);
  }

  Future<void> test_pubspec_packages_pub() async {
    var content = '''
dependencies:
  /*[0*/pub_package_1/*0]*/: 1.2.3
  /*[1*/pub_package_2/*1]*/: ^1.2.3
  /*[2*/pub_package_3/*2]*/:
  /*[3*/pub_package_4/*3]*/: any
''';

    var expectedLinks = [
      '${_pubBase}pub_package_1',
      '${_pubBase}pub_package_2',
      '${_pubBase}pub_package_3',
      '${_pubBase}pub_package_4',
    ];

    await _test_pubspec_links(content, expectedLinks);
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

    await _test_pubspec_links(content, []);
  }

  Future<void> test_pubspec_packages_withDependencyOverrides() async {
    var content = '''
dependencies:
  /*[0*/dep_package/*0]*/: 1.0.0

dependency_overrides:
  /*[1*/dep_package/*1]*/: 1.2.3
''';

    var expectedLinks = ['${_pubBase}dep_package', '${_pubBase}dep_package'];

    await _test_pubspec_links(content, expectedLinks);
  }

  Future<void> test_pubspec_packages_withDevDependencies() async {
    var content = '''
dependencies:
  /*[0*/dep_package/*0]*/: 1.2.3

dev_dependencies:
  /*[1*/dev_dep_package/*1]*/:
''';

    var expectedLinks = [
      '${_pubBase}dep_package',
      '${_pubBase}dev_dep_package',
    ];

    await _test_pubspec_links(content, expectedLinks);
  }

  Future<void> _test_analysisOptions_links(
    String content,
    List<String> expected,
  ) async {
    await _test_file_links(
      analysisOptionsUri,
      analysisOptionsPath,
      content,
      expected,
    );
  }

  Future<void> _test_file_links(
    Uri fileUri,
    String filePath,
    String content,
    List<String> expectedLinks,
  ) async {
    var code = TestCode.parse(content);

    // Combine expectedLinks with the ranges from the markers in the content
    // so we can verify both ranges and links.
    expect(expectedLinks.length, code.ranges.length);
    var expectedLinksWithRanges = expectedLinks.mapIndexed(
      (i, link) => (code.ranges[i].range, link),
    );

    newFile(filePath, code.code);

    await initialize();
    var links = await getDocumentLinks(fileUri);

    // Convert the results into the same format as expectedLinksWithRanges.
    var linkData = links!
        .map((link) => (link.range, link.target?.toString()))
        .toList();

    expect(linkData, equals(expectedLinksWithRanges));
  }

  Future<void> _test_pubspec_links(
    String content,
    List<String> expected,
  ) async {
    await _test_file_links(pubspecFileUri, pubspecFilePath, content, expected);
  }
}
