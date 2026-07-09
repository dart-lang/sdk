// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmbedderYamlLocatorTest);
  });
}

@reflectiveTest
class EmbedderYamlLocatorTest with ResourceProviderMixin {
  void test_empty() {
    var embedderYamls = locateEmbedderYamlFor(
      getFolder('/home/.pub-cache/empty'),
    );
    expect(embedderYamls, isNull);
  }

  void test_invalidYaml() {
    var foxLibPath = '/home/.pub-cache/fox/lib';
    newFolder(foxLibPath);
    newFile('/home/.pub-cache/fox/lib/_embedder.yaml', 'Text');
    var embedderYamls = locateEmbedderYamlFor(getFolder(foxLibPath));
    expect(embedderYamls, isNull);
  }

  void test_valid() {
    var foxLibPath = '/home/.pub-cache/fox/lib';
    newFolder(foxLibPath);
    newFile('/home/.pub-cache/fox/lib/_embedder.yaml', r'''
embedded_libs:
  "dart:core" : "core/core.dart"
''');
    var embedderYamls = locateEmbedderYamlFor(getFolder(foxLibPath));
    expect(embedderYamls, isNotNull);
  }

  void test_yamlIsNotMap() {
    var foxLibPath = '/home/.pub-cache/fox/lib';
    newFolder(foxLibPath);
    newFile('/home/.pub-cache/fox/lib/_embedder.yaml', r'''
- one
- two
- three
''');
    var embedderYamls = locateEmbedderYamlFor(getFolder(foxLibPath));
    expect(embedderYamls, isNull);
  }
}
