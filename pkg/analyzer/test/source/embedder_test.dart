// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.embedder_test;

import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/embedder.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/absolute_path.dart';
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

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
      expect(resolver.length, equals(0));
    });
    test('test_NoEmbedderYamls', () {
      var locator = new EmbedderYamlLocator({
        'fox': [pathTranslator.getResource('/empty')]
      });
      expect(locator.embedderYamls.length, equals(0));
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
        expect(restoreUri.toString(), equals(expected ?? dartUri));
        List<String> split = (expected ?? dartUri).split(':');
        expect(restoreUri.scheme, equals(split[0]));
        expect(restoreUri.path, equals(split[1]));
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
      expect(lib.shortName, 'fox');
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

      expectSource('dart:fox', '/tmp/slippy.dart');
      expectSource('dart:deep', '/tmp/deep/directory/file.dart');
      expectSource('dart:deep/part.dart', '/tmp/deep/directory/part.dart');
    });
  });
}

ResourceProvider resourceProvider;
TestPathTranslator pathTranslator;

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

// TODO(danrubel) if this approach works well for running tests
// in a platform specific way, then move all of the following functionality
// into a separate test utility library.

bool get isWindows => path.Style.platform == path.Style.windows;

/**
 * Assert that the given path is posix.
 */
void expectAbsolutePosixPath(String posixPath) {
  expect(posixPath, startsWith('/'),
      reason: 'Expected absolute posix path, but found $posixPath');
}

/**
 * Translate the given posixPath to a path appropriate for the
 * platform on which the tests are executing.
 */
String posixToOSPath(String posixPath) {
  expectAbsolutePosixPath(posixPath);
  if (isWindows) {
    String windowsPath = posixPath.replaceAll('/', '\\');
    if (posixPath.startsWith('/')) {
      return 'C:$windowsPath';
    }
    return windowsPath;
  }
  return posixPath;
}

/**
 * Translate the given posixPath to a file URI appropriate for the
 * platform on which the tests are executing.
 */
String posixToOSFileUri(String posixPath) {
  expectAbsolutePosixPath(posixPath);
  return isWindows ? 'file:///C:$posixPath' : 'file://$posixPath';
}

/**
 * A convenience utility for setting up a test [MemoryResourceProvider].
 * All supplied paths are assumed to be in [path.posix] format
 * and are automatically translated to [path.context].
 *
 * This class intentionally does not implement [ResourceProvider]
 * directly or indirectly so that it cannot be used as a resource provider.
 * We do not want functionality under test to interact with a resource provider
 * that automatically translates paths.
 */
class TestPathTranslator {
  final MemoryResourceProvider _provider;

  TestPathTranslator(this._provider);

  Resource getResource(String posixPath) =>
      _provider.getResource(posixToOSPath(posixPath));

  File newFile(String posixPath, String content) =>
      _provider.newFile(posixToOSPath(posixPath), content);

  Folder newFolder(String posixPath) =>
      _provider.newFolder(posixToOSPath(posixPath));
}

/**
 * A resource provider for testing that asserts that any supplied paths
 * are appropriate for the OS platform on which the tests are running.
 */
class TestResourceProvider implements ResourceProvider {
  final ResourceProvider _provider;

  TestResourceProvider(this._provider) {
    expect(_provider.absolutePathContext.separator, isWindows ? '\\' : '/');
  }

  @override
  AbsolutePathContext get absolutePathContext => _provider.absolutePathContext;

  @override
  File getFile(String path) => _provider.getFile(_assertPath(path));

  @override
  Folder getFolder(String path) => _provider.getFolder(_assertPath(path));

  @override
  Resource getResource(String path) => _provider.getResource(_assertPath(path));

  @override
  Folder getStateLocation(String pluginId) =>
      _provider.getStateLocation(pluginId);

  @override
  path.Context get pathContext => _provider.pathContext;

  /**
   * Assert that the given path is valid for the OS platform on which the
   * tests are running.
   */
  String _assertPath(String path) {
    if (isWindows) {
      if (path.contains('/')) {
        fail('Expected windows path, but found: $path');
      }
    } else {
      if (path.contains('\\')) {
        fail('Expected posix path, but found: $path');
      }
    }
    return path;
  }
}
