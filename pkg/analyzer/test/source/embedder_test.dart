// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library analyzer.test.source.embedder_test;

import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/embedder.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../embedder_tests.dart';
import '../resource_utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartUriResolverTest);
    defineReflectiveTests(EmbedderSdkTest);
    defineReflectiveTests(EmbedderUriResolverTest);
  });
}

@reflectiveTest
class DartUriResolverTest extends EmbedderRelatedTest {
  void test_embedderYaml() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(locator.embedderYamls);
    DartUriResolver resolver = new DartUriResolver(sdk);

    void expectResolved(dartUri, posixPath) {
      Source source = resolver.resolveAbsolute(Uri.parse(dartUri));
      expect(source, isNotNull, reason: dartUri);
      expect(source.fullName, posixToOSPath(posixPath));
    }

    // Check that they map to the correct paths.
    expectResolved('dart:core', '$foxLib/core.dart');
    expectResolved('dart:fox', '$foxLib/slippy.dart');
    expectResolved('dart:bear', '$foxLib/grizzly.dart');
    expectResolved('dart:relative', '$foxPath/relative.dart');
    expectResolved('dart:deep', '$foxLib/deep/directory/file.dart');
  }
}

@reflectiveTest
class EmbedderSdkTest extends EmbedderRelatedTest {
  void test_creation() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(locator.embedderYamls);

    expect(sdk.urlMappings, hasLength(5));
  }

  void test_fromFileUri() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(locator.embedderYamls);

    expectSource(String posixPath, String dartUri) {
      Uri uri = Uri.parse(posixToOSFileUri(posixPath));
      Source source = sdk.fromFileUri(uri);
      expect(source, isNotNull, reason: posixPath);
      expect(source.uri.toString(), dartUri);
      expect(source.fullName, posixToOSPath(posixPath));
    }

    expectSource('$foxLib/slippy.dart', 'dart:fox');
    expectSource('$foxLib/deep/directory/file.dart', 'dart:deep');
    expectSource('$foxLib/deep/directory/part.dart', 'dart:deep/part.dart');
  }

  void test_getSdkLibrary() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(locator.embedderYamls);

    SdkLibrary lib = sdk.getSdkLibrary('dart:fox');
    expect(lib, isNotNull);
    expect(lib.path, posixToOSPath('$foxLib/slippy.dart'));
    expect(lib.shortName, 'dart:fox');
  }

  void test_mapDartUri() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(locator.embedderYamls);

    void expectSource(String dartUri, String posixPath) {
      Source source = sdk.mapDartUri(dartUri);
      expect(source, isNotNull, reason: posixPath);
      expect(source.uri.toString(), dartUri);
      expect(source.fullName, posixToOSPath(posixPath));
    }

    expectSource('dart:core', '$foxLib/core.dart');
    expectSource('dart:fox', '$foxLib/slippy.dart');
    expectSource('dart:deep', '$foxLib/deep/directory/file.dart');
    expectSource('dart:deep/part.dart', '$foxLib/deep/directory/part.dart');
  }
}

@reflectiveTest
class EmbedderUriResolverTest extends EmbedderRelatedTest {
  void test_embedderYaml() {
    var locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    var resolver = new EmbedderUriResolver(locator.embedderYamls);

    expectResolved(dartUri, posixPath) {
      Source source = resolver.resolveAbsolute(Uri.parse(dartUri));
      expect(source, isNotNull, reason: dartUri);
      expect(source.fullName, posixToOSPath(posixPath));
    }

    // We have five mappings.
    expect(resolver, hasLength(5));
    // Check that they map to the correct paths.
    expectResolved('dart:core', '$foxLib/core.dart');
    expectResolved('dart:fox', '$foxLib/slippy.dart');
    expectResolved('dart:bear', '$foxLib/grizzly.dart');
    expectResolved('dart:relative', '$foxPath/relative.dart');
    expectResolved('dart:deep', '$foxLib/deep/directory/file.dart');
  }

  void test_nullEmbedderYamls() {
    var resolver = new EmbedderUriResolver(null);
    expect(resolver, hasLength(0));
  }

  void test_restoreAbsolute() {
    var locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    var resolver = new EmbedderUriResolver(locator.embedderYamls);

    expectRestore(String dartUri, [String expected]) {
      var parsedUri = Uri.parse(dartUri);
      var source = resolver.resolveAbsolute(parsedUri);
      expect(source, isNotNull);
      // Restore source's uri.
      var restoreUri = resolver.restoreAbsolute(source);
      expect(restoreUri, isNotNull, reason: dartUri);
      // Verify that it is 'dart:fox'.
      expect(restoreUri.toString(), expected ?? dartUri);
      List<String> split = (expected ?? dartUri).split(':');
      expect(restoreUri.scheme, split[0]);
      expect(restoreUri.path, split[1]);
    }

    expectRestore('dart:deep');
    expectRestore('dart:deep/file.dart', 'dart:deep');
    expectRestore('dart:deep/part.dart');
    expectRestore('dart:deep/deep/file.dart');
  }
}
