// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.embedder_test;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/embedder.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../utils.dart';

main() {
  initializeTestEnvironment();
  group('EmbedderUriResolverTest', () {
    setUp(() {
      buildResourceProvider();
    });
    tearDown(() {
      clearResourceProvider();
    });
    test('test_NullEmbedderYamls', () {
      var resolver = new EmbedderUriResolver(null);
      expect(resolver.length, equals(0));
    });
    test('test_NoEmbedderYamls', () {
      var locator = new EmbedderYamlLocator({
        'fox': [resourceProvider.getResource('/empty')]
      });
      expect(locator.embedderYamls.length, equals(0));
    });
    test('test_EmbedderYaml', () {
      var locator = new EmbedderYamlLocator({
        'fox': [resourceProvider.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);

      expectResolved(dartUri, filePath) {
        Source source = resolver.resolveAbsolute(Uri.parse(dartUri));
        expect(source, isNotNull, reason: dartUri);
        expect(source.fullName, filePath);
      }

      // We have four mappings.
      expect(resolver.length, equals(4));
      // Check that they map to the correct paths.
      expectResolved('dart:fox', '/tmp/slippy.dart');
      expectResolved('dart:bear', '/tmp/grizzly.dart');
      expectResolved('dart:relative', '/relative.dart');
      expectResolved('dart:deep', '/tmp/deep/directory/file.dart');
    });
    test('test_BadYAML', () {
      var locator = new EmbedderYamlLocator(null);
      locator.addEmbedderYaml(null, r'''{{{,{{}}},}}''');
      expect(locator.embedderYamls.length, equals(0));
    });
    test('test_restoreAbsolute', () {
      var locator = new EmbedderYamlLocator({
        'fox': [resourceProvider.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);

      expectRestore(String dartUri, [String expected]) {
        var source = resolver.resolveAbsolute(Uri.parse(dartUri));
        expect(source, isNotNull);
        // Restore source's uri.
        var restoreUri = resolver.restoreAbsolute(source);
        expect(restoreUri, isNotNull, reason: dartUri);
        // Verify that it is 'dart:fox'.
        expect(restoreUri.toString(), equals(expected ?? dartUri));
        List<String> split = (expected ?? dartUri).split(':');
        expect(restoreUri.scheme, equals(split[0]));
        expect(restoreUri.path, equals(split[1]));
      }

      try {
        expectRestore('dart:deep');
        expectRestore('dart:deep/file.dart', 'dart:deep');
        expectRestore('dart:deep/part.dart');
        expectRestore('dart:deep/deep/file.dart');
        if (JavaFile.separator == '\\') {
          // See https://github.com/dart-lang/sdk/issues/25498
          fail('expected to fail on Windows');
        }
      } catch (_) {
        // Test is broken on Windows, but should run elsewhere
        if (JavaFile.separator != '\\') {
          rethrow;
        }
      }
    });

    test('test_EmbedderSdk_fromFileUri', () {
      var locator = new EmbedderYamlLocator({
        'fox': [resourceProvider.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);
      var sdk = resolver.dartSdk;

      expectSource(String filePath, String dartUri) {
        var uri = Uri.parse(filePath);
        var source = sdk.fromFileUri(uri);
        expect(source, isNotNull, reason: filePath);
        expect(source.uri.toString(), dartUri);
        expect(source.fullName, filePath);
      }

      expectSource('/tmp/slippy.dart', 'dart:fox');
      expectSource('/tmp/deep/directory/file.dart', 'dart:deep');
      expectSource('/tmp/deep/directory/part.dart', 'dart:deep/part.dart');
    });
    test('test_EmbedderSdk_getSdkLibrary', () {
      var locator = new EmbedderYamlLocator({
        'fox': [resourceProvider.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);
      var sdk = resolver.dartSdk;
      var lib = sdk.getSdkLibrary('dart:fox');
      expect(lib, isNotNull);
      expect(lib.path, '/tmp/slippy.dart');
      expect(lib.shortName, 'fox');
    });
    test('test_EmbedderSdk_mapDartUri', () {
      var locator = new EmbedderYamlLocator({
        'fox': [resourceProvider.getResource('/tmp')]
      });
      var resolver = new EmbedderUriResolver(locator.embedderYamls);
      var sdk = resolver.dartSdk;

      expectSource(String dartUri, String filePath) {
        var source = sdk.mapDartUri(dartUri);
        expect(source, isNotNull, reason: filePath);
        expect(source.uri.toString(), dartUri);
        expect(source.fullName, filePath.replaceAll('/', JavaFile.separator));
      }

      expectSource('dart:fox', '/tmp/slippy.dart');
      expectSource('dart:deep', '/tmp/deep/directory/file.dart');
      expectSource('dart:deep/part.dart', '/tmp/deep/directory/part.dart');
    });
  });
}

MemoryResourceProvider resourceProvider;

buildResourceProvider() {
  resourceProvider = new MemoryResourceProvider();
  resourceProvider.newFolder('/empty');
  resourceProvider.newFolder('/tmp');
  resourceProvider.newFile(
      '/tmp/_embedder.yaml',
      r'''
embedder_libs:
  "dart:fox": "slippy.dart"
  "dart:bear": "grizzly.dart"
  "dart:relative": "../relative.dart"
  "dart:deep": "deep/directory/file.dart"
  "fart:loudly": "nomatter.dart"
''');
}

clearResourceProvider() {
  resourceProvider = null;
}
