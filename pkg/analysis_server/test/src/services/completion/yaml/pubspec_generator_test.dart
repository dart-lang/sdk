// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/pubspec_generator.dart';
import 'package:analysis_server/src/services/pub/pub_api.dart';
import 'package:analysis_server/src/services/pub/pub_command.dart';
import 'package:analysis_server/src/services/pub/pub_package_service.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../mocks.dart';
import 'yaml_generator_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecGeneratorTest);
  });
}

@reflectiveTest
class PubspecGeneratorTest extends YamlGeneratorTest {
  late MockHttpClient httpClient;
  late MockProcessRunner processRunner;

  late PubPackageService pubPackageService;

  @override
  String get fileName => file_paths.pubspecYaml;

  @override
  PubspecGenerator get generator =>
      PubspecGenerator(resourceProvider, pubPackageService);

  void setUp() {
    httpClient = MockHttpClient();
    processRunner = MockProcessRunner();
    pubPackageService = PubPackageService(
        InstrumentationService.NULL_SERVICE,
        resourceProvider,
        PubApi(InstrumentationService.NULL_SERVICE, httpClient, null),
        PubCommand(InstrumentationService.NULL_SERVICE, processRunner));
  }

  void tearDown() {
    pubPackageService.shutdown();
  }

  void test_empty() {
    getCompletions('^');
    assertSuggestion('flutter: ');
    assertSuggestion('name: ');
    assertSuggestion('topics: ');
  }

  void test_emptyPreviousSibling() {
    // Ensure handling of nulls does not pick up nulls from previous siblings
    getCompletions('''
flutter:
  assets:
  fonts:
    ^
''');
    assertSuggestion('family: ');
  }

  void test_environment() {
    getCompletions('''
environment:
  ^
''');
    assertSuggestion('flutter: ');
    assertSuggestion('sdk: ');
  }

  void test_flutter() {
    getCompletions('''
flutter:
  ^
''');
    assertSuggestion('assets:');
    assertSuggestion('plugin: ');
  }

  void test_flutter_assets_invalidPath() {
    newFile('/home/test/assets/img1.jpg', '');
    getCompletions('''
flutter:
  assets:
    - assets?im^
''');
    assertNoSuggestion('img1.jpg');
  }

  void test_flutter_assets_nonExistentPath() {
    newFile('/home/test/assets/img1.jpg', '');
    getCompletions('''
flutter:
  assets:
    - asets/im^
''');
    assertNoSuggestion('img1.jpg');
  }

  void test_flutter_assets_noPath() {
    newFile('/home/test/assets/img1.jpg', '');
    getCompletions('''
flutter:
  assets:
    - ^
''');
    assertSuggestion('assets');
  }

  void test_flutter_assets_partialPath() {
    newFile('/home/test/assets/img1.jpg', '');
    getCompletions('''
flutter:
  assets:
    - assets/im^
''');
    assertSuggestion('img1.jpg');
  }

  void test_flutter_assets_path_withFollowing() {
    newFile('/home/test/assets/img1.jpg', '');
    getCompletions('''
flutter:
  assets:
    - assets/^img
''');
    assertSuggestion('img1.jpg');
  }

  void test_flutter_assets_path_withoutFollowing() {
    newFile('/home/test/assets/img1.jpg', '');
    getCompletions('''
flutter:
  assets:
    - assets/^
''');
    assertSuggestion('img1.jpg');
  }

  void test_flutter_fonts() {
    getCompletions('''
flutter:
  fonts:
    ^
''');
    assertSuggestion('family: ');
    assertSuggestion('fonts:');
  }

  void test_flutter_fonts_fonts() {
    getCompletions('''
flutter:
  fonts:
    - fonts:
        ^
''');
    assertSuggestion('asset: ');
  }

  void test_flutter_fonts_fonts_style() {
    getCompletions('''
flutter:
  fonts:
    - fonts:
       - style: ^
''');
    assertSuggestion('italic');
  }

  void test_flutter_fonts_weight() {
    getCompletions('''
flutter:
  fonts:
    - fonts:
        - weight: ^
''');
    assertSuggestion('100');
    assertSuggestion('900');
  }

  void test_flutter_module() {
    getCompletions('''
flutter:
  module:
    ^
''');
    assertSuggestion('androidX: ');
    assertSuggestion('iosBundleIdentifier: ');
  }

  void test_flutter_plugin() {
    getCompletions('''
flutter:
  plugin:
    ^
''');
    assertSuggestion('platforms: ');
  }

  void test_flutter_plugin_platforms() {
    getCompletions('''
flutter:
  plugin:
    platforms:
      ^
''');
    assertSuggestion('android: ');
    assertSuggestion('web: ');
  }

  void test_flutter_plugin_platforms_android() {
    getCompletions('''
flutter:
  plugin:
    platforms:
      android:
        ^
''');
    assertSuggestion('package: ');
    assertSuggestion('pluginClass: ');
  }

  void test_flutter_plugin_platforms_ios() {
    getCompletions('''
flutter:
  plugin:
    platforms:
      ios:
        ^
''');
    assertSuggestion('pluginClass: ');
  }

  void test_flutter_plugin_platforms_linux() {
    getCompletions('''
flutter:
  plugin:
    platforms:
      linux:
        ^
''');
    assertSuggestion('dartPluginClass: ');
    assertSuggestion('pluginClass: ');
  }

  void test_flutter_plugin_platforms_macos() {
    getCompletions('''
flutter:
  plugin:
    platforms:
      macos:
        ^
''');
    assertSuggestion('dartPluginClass: ');
    assertSuggestion('pluginClass: ');
  }

  void test_flutter_plugin_platforms_web() {
    getCompletions('''
flutter:
  plugin:
    platforms:
      web:
        ^
''');
    assertSuggestion('fileName: ');
    assertSuggestion('pluginClass: ');
  }

  void test_flutter_plugin_platforms_windows() {
    getCompletions('''
flutter:
  plugin:
    platforms:
      windows:
        ^
''');
    assertSuggestion('dartPluginClass: ');
    assertSuggestion('pluginClass: ');
  }

  void test_flutter_usesMaterialDesign() {
    getCompletions('''
flutter:
  uses-material-design: ^
''');
    assertSuggestion('true');
  }

  void test_packageName() async {
    /// Sample package name list JSON in the same format as the API:
    /// https://pub.dev/api/package-name-completion-data
    const samplePackageList = '''
  { "packages": ["one", "two", "three"] }
  ''';

    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.toString().endsWith(PubApi.packageNameListPath)) {
        return Response(samplePackageList, 200);
      } else {
        throw UnimplementedError();
      }
    };

    pubPackageService.beginPackageNamePreload();
    await pumpEventQueue();

    getCompletions('''
dependencies:
  ^
''');
    assertSuggestion('one: ');
    assertSuggestion('two: ');
  }

  void test_packageName_invalidYaml() async {
    const samplePackageList = '''
  { "packages": ["one", "two", "three"] }
  ''';

    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.toString().endsWith(PubApi.packageNameListPath)) {
        return Response(samplePackageList, 200);
      } else {
        throw UnimplementedError();
      }
    };

    pubPackageService.beginPackageNamePreload();
    await pumpEventQueue();

    getCompletions('''
dependencies:
  one:
  tw^
  three:
''');
    assertSuggestion('two: ');
  }

  void test_packageVersion() async {
    final json = r'''
    {
      "packages": [
        {
          "package":    "one",
          "latest":     { "version": "3.2.1" },
          "resolvable": { "version": "1.2.4" }
        }
      ]
    }
    ''';
    processRunner.startHandler =
        (executable, args, {dir, env}) => MockProcess(1, 0, json, '');

    pubPackageService.beginCachePreloads([convertPath('/home/test/$fileName')]);
    await pumpEventQueue(times: 500);

    getCompletions('''
dependencies:
  one: ^
''');
    assertSuggestion('^1.2.4');
    assertSuggestion('^3.2.1');
  }

  /// Ensure in a repo with a DEPS file like the SDK, we do not run pub
  /// processes to cache the version numbers.
  void test_packageVersion_withDEPSfile() async {
    var didRun = false;
    processRunner.startHandler = (executable, args, {dir, env}) {
      didRun = true;
      return MockProcess(1, 0, '', '');
    };

    newFile('/home/DEPS', '');
    pubPackageService.beginCachePreloads([convertPath('/home/test/$fileName')]);
    await pumpEventQueue(times: 500);

    expect(didRun, isFalse);
  }

  void test_screenshots_description() {
    getCompletions('''
screenshots:
  - d^
''');
    assertSuggestion('description: ');
  }

  void test_screenshots_path() {
    getCompletions('''
screenshots:
  - description: 'One'
    path: /path/to/ss.png
  - description: 'Two' 
    ^
''');
    assertSuggestion('path: ');
  }
}
