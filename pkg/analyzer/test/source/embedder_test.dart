// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.embedder_test;

import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/embedder.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../resource_utils.dart';
import '../utils.dart';

main() {
  group('EmbedderUriResolverTest', () {
    setUp(() {
      initializeTestEnvironment(path.context);
      buildResourceProvider();
    });
    tearDown(() {
      initializeTestEnvironment();
      clearResourceProvider();
    });
    test('test_NullEmbedderYamls', () {
      var resolver = new EmbedderUriResolver(null);
      expect(resolver.length, 0);
    });
    test('test_NoEmbedderYamls', () {
      var locator = new EmbedderYamlLocator({
        'fox': [pathTranslator.getResource('/empty')]
      });
      expect(locator.embedderYamls.length, 0);
    });
    test('test_EmbedderYaml', () {
      var locator = new EmbedderYamlLocator({
        'fox': [pathTranslator.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);

      expectResolved(dartUri, posixPath) {
        Source source = resolver.resolveAbsolute(Uri.parse(dartUri));
        expect(source, isNotNull, reason: dartUri);
        expect(source.fullName, posixToOSPath(posixPath));
      }

      // We have five mappings.
      expect(resolver.length, 5);
      // Check that they map to the correct paths.
      expectResolved('dart:core', '/tmp/core.dart');
      expectResolved('dart:fox', '/tmp/slippy.dart');
      expectResolved('dart:bear', '/tmp/grizzly.dart');
      expectResolved('dart:relative', '/relative.dart');
      expectResolved('dart:deep', '/tmp/deep/directory/file.dart');
    });
    test('test_BadYAML', () {
      var locator = new EmbedderYamlLocator(null);
      locator.addEmbedderYaml(null, r'''{{{,{{}}},}}''');
      expect(locator.embedderYamls.length, 0);
    });
    test('test_restoreAbsolute', () {
      var locator = new EmbedderYamlLocator({
        'fox': [pathTranslator.getResource('/tmp')]
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
    });

    test('test_EmbedderSdk_fromFileUri', () {
      var locator = new EmbedderYamlLocator({
        'fox': [pathTranslator.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);
      var sdk = resolver.dartSdk;

      expectSource(String posixPath, String dartUri) {
        var uri = Uri.parse(posixToOSFileUri(posixPath));
        var source = sdk.fromFileUri(uri);
        expect(source, isNotNull, reason: posixPath);
        expect(source.uri.toString(), dartUri);
        expect(source.fullName, posixToOSPath(posixPath));
      }

      expectSource('/tmp/slippy.dart', 'dart:fox');
      expectSource('/tmp/deep/directory/file.dart', 'dart:deep');
      expectSource('/tmp/deep/directory/part.dart', 'dart:deep/part.dart');
    });
    test('test_EmbedderSdk_getSdkLibrary', () {
      var locator = new EmbedderYamlLocator({
        'fox': [pathTranslator.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);
      var sdk = resolver.dartSdk;
      var lib = sdk.getSdkLibrary('dart:fox');
      expect(lib, isNotNull);
      expect(lib.path, posixToOSPath('/tmp/slippy.dart'));
      expect(lib.shortName, 'dart:fox');
    });
    test('test_EmbedderSdk_mapDartUri', () {
      var locator = new EmbedderYamlLocator({
        'fox': [pathTranslator.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);
      var sdk = resolver.dartSdk;

      expectSource(String dartUri, String posixPath) {
        var source = sdk.mapDartUri(dartUri);
        expect(source, isNotNull, reason: posixPath);
        expect(source.uri.toString(), dartUri);
        expect(source.fullName, posixToOSPath(posixPath));
      }

      expectSource('dart:core', '/tmp/core.dart');
      expectSource('dart:fox', '/tmp/slippy.dart');
      expectSource('dart:deep', '/tmp/deep/directory/file.dart');
      expectSource('dart:deep/part.dart', '/tmp/deep/directory/part.dart');
    });
  });
}

TestPathTranslator pathTranslator;
ResourceProvider resourceProvider;

buildResourceProvider() {
  var rawProvider = new MemoryResourceProvider(isWindows: isWindows);
  resourceProvider = new TestResourceProvider(rawProvider);
  pathTranslator = new TestPathTranslator(rawProvider)
    ..newFolder('/empty')
    ..newFolder('/tmp')
    ..newFile(
        '/tmp/_embedder.yaml',
        r'''
embedded_libs:
  "dart:core" : "core.dart"
  "dart:fox": "slippy.dart"
  "dart:bear": "grizzly.dart"
  "dart:relative": "../relative.dart"
  "dart:deep": "deep/directory/file.dart"
  "fart:loudly": "nomatter.dart"
''');
}

clearResourceProvider() {
  resourceProvider = null;
  pathTranslator = null;
}
