// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.source.embedder;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/embedder.dart';
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
      // We have four mappings.
      expect(resolver.length, equals(4));
      // Check that they map to the correct paths.
      expect(resolver['dart:fox'], equals("/tmp/slippy.dart"));
      expect(resolver['dart:bear'], equals("/tmp/grizzly.dart"));
      expect(resolver['dart:relative'], equals("/relative.dart"));
      expect(resolver['dart:deep'], equals("/tmp/deep/directory/file.dart"));
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
      var source = resolver.resolveAbsolute(Uri.parse('dart:fox'));
      expect(source, isNotNull);
      // Restore source's uri.
      var restoreUri = resolver.restoreAbsolute(source);
      expect(restoreUri, isNotNull);
      // Verify that it is 'dart:fox'.
      expect(restoreUri.toString(), equals('dart:fox'));
      expect(restoreUri.scheme, equals('dart'));
      expect(restoreUri.path, equals('fox'));
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
