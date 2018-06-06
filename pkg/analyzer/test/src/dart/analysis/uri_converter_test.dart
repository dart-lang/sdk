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
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../context/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DriverBasedUriConverterTest);
  });
}

@reflectiveTest
class DriverBasedUriConverterTest extends Object with ResourceProviderMixin {
  DriverBasedUriConverter uriConverter;

  void setUp() {
    resourceProvider = new MemoryResourceProvider();

    Folder barFolder = newFolder('/packages/bar/lib');
    Folder fooFolder = newFolder('/packages/foo/lib');

    SourceFactory sourceFactory = new SourceFactory([
      new DartUriResolver(new MockSdk(resourceProvider: resourceProvider)),
      new PackageMapUriResolver(resourceProvider, {
        'foo': [fooFolder],
        'bar': [barFolder],
      }),
      new ResourceUriResolver(resourceProvider),
    ], null, resourceProvider);

    ContextRoot contextRoot = new ContextRoot(barFolder.path, [],
        pathContext: resourceProvider.pathContext);

    MockAnalysisDriver driver = new MockAnalysisDriver();
    driver.resourceProvider = resourceProvider;
    driver.sourceFactory = sourceFactory;
    driver.contextRoot = contextRoot;

    uriConverter = new DriverBasedUriConverter(driver);
  }

  test_pathToUri_dart() {
    expect(uriConverter.pathToUri(convertPath('/sdk/lib/core/core.dart')),
        Uri.parse('dart:core'));
  }

  test_pathToUri_notRelative() {
    expect(
        uriConverter.pathToUri(convertPath('/packages/foo/lib/foo.dart'),
            containingPath: convertPath('/packages/bar/lib/bar.dart')),
        Uri.parse('package:foo/foo.dart'));
  }

  test_pathToUri_package() {
    expect(uriConverter.pathToUri(convertPath('/packages/foo/lib/foo.dart')),
        Uri.parse('package:foo/foo.dart'));
  }

  test_pathToUri_relative() {
    expect(
        uriConverter.pathToUri(convertPath('/packages/bar/lib/src/baz.dart'),
            containingPath: convertPath('/packages/bar/lib/bar.dart')),
        Uri.parse('src/baz.dart'));
  }

  test_uriToPath_dart() {
    expect(uriConverter.uriToPath(Uri.parse('dart:core')),
        convertPath('/sdk/lib/core/core.dart'));
  }

  test_uriToPath_package() {
    expect(uriConverter.uriToPath(Uri.parse('package:foo/foo.dart')),
        convertPath('/packages/foo/lib/foo.dart'));
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
