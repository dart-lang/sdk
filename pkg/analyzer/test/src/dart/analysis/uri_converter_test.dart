// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/uri_converter.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../context/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DriverBasedUriConverterTest);
  });
}

@reflectiveTest
class DriverBasedUriConverterTest {
  MemoryResourceProvider resourceProvider;
  DriverBasedUriConverter uriConverter;

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    Folder packageFolder = resourceProvider.newFolder('/packages/bar/lib');

    SourceFactory sourceFactory = new SourceFactory([
      new DartUriResolver(new MockSdk(resourceProvider: resourceProvider)),
      new PackageMapUriResolver(resourceProvider, {
        'foo': [resourceProvider.newFolder('/packages/foo/lib')],
        'bar': [packageFolder],
      }),
      new ResourceUriResolver(resourceProvider),
    ], null, resourceProvider);

    ContextRoot contextRoot = new ContextRoot(packageFolder.path, [],
        pathContext: resourceProvider.pathContext);

    MockAnalysisDriver driver = new MockAnalysisDriver();
    driver.resourceProvider = resourceProvider;
    driver.sourceFactory = sourceFactory;
    driver.contextRoot = contextRoot;

    uriConverter = new DriverBasedUriConverter(driver);
  }

  test_pathToUri_dart() {
    expect(
        uriConverter
            .pathToUri(resourceProvider.convertPath('/sdk/lib/core/core.dart')),
        Uri.parse('dart:core'));
  }

  test_pathToUri_notRelative() {
    expect(
        uriConverter.pathToUri(
            resourceProvider.convertPath('/packages/foo/lib/foo.dart'),
            containingPath:
                resourceProvider.convertPath('/packages/bar/lib/bar.dart')),
        Uri.parse('package:foo/foo.dart'));
  }

  test_pathToUri_package() {
    expect(
        uriConverter.pathToUri(
            resourceProvider.convertPath('/packages/foo/lib/foo.dart')),
        Uri.parse('package:foo/foo.dart'));
  }

  test_pathToUri_relative() {
    expect(
        uriConverter.pathToUri(
            resourceProvider.convertPath('/packages/bar/lib/src/baz.dart'),
            containingPath:
                resourceProvider.convertPath('/packages/bar/lib/bar.dart')),
        Uri.parse('src/baz.dart'));
  }

  test_uriToPath_dart() {
    expect(uriConverter.uriToPath(Uri.parse('dart:core')),
        resourceProvider.convertPath('/sdk/lib/core/core.dart'));
  }

  test_uriToPath_package() {
    expect(uriConverter.uriToPath(Uri.parse('package:foo/foo.dart')),
        resourceProvider.convertPath('/packages/foo/lib/foo.dart'));
  }
}

class MockAnalysisDriver implements AnalysisDriver {
  ResourceProvider resourceProvider;
  SourceFactory sourceFactory;
  ContextRoot contextRoot;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    fail('Unexpected invocation of ${invocation.memberName}');
  }
}
