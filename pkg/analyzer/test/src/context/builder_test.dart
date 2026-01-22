// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../embedder_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmbedderYamlLocatorTest);
  });
}

@reflectiveTest
class EmbedderYamlLocatorTest extends EmbedderRelatedTest {
  void test_empty() {
    var locator = EmbedderYamlLocator.forLibFolder(getFolder(emptyPath));
    expect(locator.embedderYamls, isEmpty);
  }

  void test_valid() {
    var locator = EmbedderYamlLocator.forLibFolder(getFolder(foxLib));
    expect(locator.embedderYamls, hasLength(1));
  }
}
