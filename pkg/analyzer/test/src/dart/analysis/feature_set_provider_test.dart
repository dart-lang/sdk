// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FeatureSetProviderTest);
  });
}

@reflectiveTest
class FeatureSetProviderTest with ResourceProviderMixin {
  MockSdk mockSdk;
  SourceFactory sourceFactory;
  FeatureSetProvider provider;

  void setUp() {
    newFile('/test/lib/test.dart', content: '');

    mockSdk = MockSdk(resourceProvider: resourceProvider);
    _createSourceFactory();
  }

  test_packages() {
    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: newFolder('/packages/aaa'),
          libFolder: newFolder('/packages/aaa/lib'),
          languageVersion: null,
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: newFolder('/packages/bbb'),
          libFolder: newFolder('/packages/bbb/lib'),
          languageVersion: Version(2, 7, 0),
        ),
        'ccc': Package(
          name: 'ccc',
          rootFolder: newFolder('/packages/ccc'),
          libFolder: newFolder('/packages/ccc/lib'),
          languageVersion: Version(2, 8, 0),
        ),
      },
    );

    _createSourceFactory(
      packageUriResolver: _createPackageMapUriResolver(packages),
    );

    provider = FeatureSetProvider.build(
      resourceProvider: resourceProvider,
      packages: packages,
      packageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
      nonPackageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
    );

    _assertNonNullableForPath('/packages/aaa/a.dart', false);
    _assertNonNullableForPath('/packages/aaa/lib/b.dart', false);
    _assertNonNullableForPath('/packages/aaa/test/c.dart', false);

    _assertNonNullableForPath('/packages/bbb/a.dart', false);
    _assertNonNullableForPath('/packages/bbb/lib/b.dart', false);
    _assertNonNullableForPath('/packages/bbb/test/c.dart', false);

    _assertNonNullableForPath('/packages/ccc/a.dart', false);
    _assertNonNullableForPath('/packages/ccc/lib/b.dart', false);
    _assertNonNullableForPath('/packages/ccc/test/c.dart', false);

    _assertNonNullableForPath('/other/file.dart', false);
  }

  test_packages_enabledExperiment_nonNullable() {
    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: newFolder('/packages/aaa'),
          libFolder: newFolder('/packages/aaa/lib'),
          languageVersion: null,
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: newFolder('/packages/bbb'),
          libFolder: newFolder('/packages/bbb/lib'),
          languageVersion: Version(2, 7, 0),
        ),
        'ccc': Package(
          name: 'ccc',
          rootFolder: newFolder('/packages/ccc'),
          libFolder: newFolder('/packages/ccc/lib'),
          languageVersion: Version(2, 8, 0),
        ),
      },
    );

    _createSourceFactory(
      packageUriResolver: _createPackageMapUriResolver(packages),
    );

    provider = FeatureSetProvider.build(
      resourceProvider: resourceProvider,
      packages: packages,
      packageDefaultFeatureSet: FeatureSet.fromEnableFlags(['non-nullable']),
      nonPackageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
    );

    _assertNonNullableForPath('/packages/aaa/a.dart', true);
    _assertNonNullableForPath('/packages/aaa/lib/b.dart', true);
    _assertNonNullableForPath('/packages/aaa/test/c.dart', true);

    _assertNonNullableForPath('/packages/bbb/a.dart', false);
    _assertNonNullableForPath('/packages/bbb/lib/b.dart', false);
    _assertNonNullableForPath('/packages/bbb/test/c.dart', false);

    _assertNonNullableForPath('/packages/ccc/a.dart', true);
    _assertNonNullableForPath('/packages/ccc/lib/b.dart', true);
    _assertNonNullableForPath('/packages/ccc/test/c.dart', true);

    _assertNonNullableForPath('/other/file.dart', false);
  }

  test_sdk() {
    _buildProvider([]);

    var featureSet = _getSdkFeatureSet();
    expect(featureSet.isEnabled(Feature.non_nullable), isTrue);
  }

  test_sdk_enabledExperiment_nonNullable() {
    _buildProvider(['non-nullable']);

    var featureSet = _getSdkFeatureSet();
    expect(featureSet.isEnabled(Feature.non_nullable), isTrue);
  }

  void _assertNonNullableForPath(String path, bool expected) {
    var featureSet = _getPathFeatureSet(path);
    expect(featureSet.isEnabled(Feature.non_nullable), expected);
  }

  void _buildProvider(List<String> enabledExperiments) {
    var featureSet = FeatureSet.fromEnableFlags(enabledExperiments);
    provider = FeatureSetProvider.build(
      resourceProvider: resourceProvider,
      packages: findPackagesFrom(resourceProvider, getFolder('/test')),
      packageDefaultFeatureSet: featureSet,
      nonPackageDefaultFeatureSet: featureSet,
    );
  }

  PackageMapUriResolver _createPackageMapUriResolver(Packages packages) {
    var map = <String, List<Folder>>{};
    for (var package in packages.packages) {
      map[package.name] = [package.libFolder];
    }
    return PackageMapUriResolver(resourceProvider, map);
  }

  void _createSourceFactory({UriResolver packageUriResolver}) {
    var resolvers = <UriResolver>[];
    if (packageUriResolver != null) {
      resolvers.add(packageUriResolver);
    }
    resolvers.addAll([
      DartUriResolver(mockSdk),
      ResourceUriResolver(resourceProvider),
    ]);
    sourceFactory = SourceFactoryImpl(resolvers);
  }

  FeatureSet _getPathFeatureSet(String path) {
    path = convertPath(path);
    var fileUri = toUri(path);
    var fileSource = sourceFactory.forUri2(fileUri);
    var uri = sourceFactory.restoreUri(fileSource);
    return provider.getFeatureSet(path, uri);
  }

  FeatureSet _getSdkFeatureSet() {
    var mathUri = Uri.parse('dart:math');
    var mathPath = sourceFactory.forUri2(mathUri).fullName;
    return provider.getFeatureSet(mathPath, mathUri);
  }
}
