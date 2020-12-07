// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/pubspec_generator.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'yaml_generator_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecGeneratorTest);
  });
}

@reflectiveTest
class PubspecGeneratorTest extends YamlGeneratorTest {
  @override
  String get fileName => 'pubspec.yaml';

  @override
  PubspecGenerator get generator => PubspecGenerator(resourceProvider);

  void test_empty() {
    getCompletions('^');
    assertSuggestion('flutter: ');
    assertSuggestion('name: ');
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
    newFile('/home/test/assets/img1.jpg');
    getCompletions('''
flutter:
  assets:
    - assets?im^
''');
    assertNoSuggestion('img1.jpg');
  }

  void test_flutter_assets_nonExistentPath() {
    newFile('/home/test/assets/img1.jpg');
    getCompletions('''
flutter:
  assets:
    - asets/im^
''');
    assertNoSuggestion('img1.jpg');
  }

  void test_flutter_assets_noPath() {
    newFile('/home/test/assets/img1.jpg');
    getCompletions('''
flutter:
  assets:
    - ^
''');
    assertSuggestion('assets');
  }

  void test_flutter_assets_partialPath() {
    newFile('/home/test/assets/img1.jpg');
    getCompletions('''
flutter:
  assets:
    - assets/im^
''');
    assertSuggestion('img1.jpg');
  }

  void test_flutter_assets_path_withFollowing() {
    newFile('/home/test/assets/img1.jpg');
    getCompletions('''
flutter:
  assets:
    - assets/^img
''');
    assertSuggestion('img1.jpg');
  }

  void test_flutter_assets_path_withoutFollowing() {
    newFile('/home/test/assets/img1.jpg');
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
}
