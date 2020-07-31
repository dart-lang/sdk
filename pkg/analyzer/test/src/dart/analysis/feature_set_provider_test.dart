// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
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

  test_packages_allowedExperiments() {
    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: newFolder('/packages/aaa'),
          libFolder: newFolder('/packages/aaa/lib'),
          languageVersion: Version(2, 7, 0),
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: newFolder('/packages/bbb'),
          libFolder: newFolder('/packages/bbb/lib'),
          languageVersion: Version(2, 7, 0),
        ),
      },
    );

    _createSourceFactory(
      packageUriResolver: _createPackageMapUriResolver(packages),
    );

    _newSdkExperimentsFile(r'''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": "nullSafety"
    }
  },
  "packages": {
    "aaa": {
      "experimentSet": "nullSafety"
    }
  }
}
''');

    provider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      packages: packages,
      packageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
      nonPackageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
    );

    _assertNonNullableForPath('/packages/aaa/lib/a.dart', true);
    _assertNonNullableForPath('/packages/aaa/bin/b.dart', true);
    _assertNonNullableForPath('/packages/aaa/test/c.dart', true);

    _assertNonNullableForPath('/packages/bbb/lib/a.dart', false);
    _assertNonNullableForPath('/packages/bbb/bin/b.dart', false);
    _assertNonNullableForPath('/packages/bbb/test/c.dart', false);

    _assertNonNullableForPath('/other/file.dart', false);
  }

  test_packages_contextExperiments_empty() {
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
      sourceFactory: sourceFactory,
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

  test_packages_contextExperiments_nested() {
    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: getFolder('/packages/aaa'),
          libFolder: getFolder('/packages/aaa/lib'),
          languageVersion: Version.parse('2.5.0'),
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: getFolder('/packages/aaa/bbb'),
          libFolder: getFolder('/packages/aaa/bbb/lib'),
          languageVersion: Version.parse('2.6.0'),
        ),
        'ccc': Package(
          name: 'ccc',
          rootFolder: getFolder('/packages/ccc'),
          libFolder: getFolder('/packages/ccc/lib'),
          languageVersion: Version.parse('2.7.0'),
        ),
      },
    );

    provider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      packages: packages,
      packageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
      nonPackageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
    );

    void check(String posixPath, Version expected) {
      var path = convertPath(posixPath);
      var uri = Uri.parse('package:aaa/a.dart');
      expect(
        provider.getLanguageVersion(path, uri),
        expected,
      );
    }

    check('/packages/aaa/a.dart', Version.parse('2.5.0'));
    check('/packages/aaa/bbb/b.dart', Version.parse('2.6.0'));
    check('/packages/ccc/c.dart', Version.parse('2.7.0'));
    check('/packages/ddd/d.dart', ExperimentStatus.currentVersion);
  }

  test_packages_contextExperiments_nonNullable() {
    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: newFolder('/packages/aaa'),
          libFolder: newFolder('/packages/aaa/lib'),
          languageVersion: null,
        ),
      },
    );

    _createSourceFactory(
      packageUriResolver: _createPackageMapUriResolver(packages),
    );

    provider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      packages: packages,
      packageDefaultFeatureSet: FeatureSet.fromEnableFlags(['non-nullable']),
      nonPackageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
    );

    _assertNonNullableForPath('/packages/aaa/a.dart', true);
    _assertNonNullableForPath('/packages/aaa/lib/b.dart', true);
    _assertNonNullableForPath('/packages/aaa/test/c.dart', true);

    _assertNonNullableForPath('/other/file.dart', false);
  }

  test_sdk_allowedExperiments_default() {
    _newSdkExperimentsFile(r'''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": "nullSafety"
    }
  }
}
''');

    provider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      packages: findPackagesFrom(resourceProvider, getFolder('/test')),
      packageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
      nonPackageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
    );

    var featureSet = _getSdkFeatureSet('dart:math');
    expect(featureSet.isEnabled(Feature.non_nullable), isTrue);
  }

  test_sdk_allowedExperiments_library() {
    _newSdkExperimentsFile(r'''
{
  "version": 1,
  "experimentSets": {
    "none": [],
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": "none"
    },
    "libraries": {
      "math": {
        "experimentSet": "nullSafety"
      }
    }
  }
}
''');
    provider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      packages: findPackagesFrom(resourceProvider, getFolder('/test')),
      packageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
      nonPackageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
    );

    var core_featureSet = _getSdkFeatureSet('dart:core');
    expect(core_featureSet.isEnabled(Feature.non_nullable), isFalse);

    var math_featureSet = _getSdkFeatureSet('dart:math');
    expect(math_featureSet.isEnabled(Feature.non_nullable), isTrue);
  }

  test_sdk_allowedExperiments_mockDefault() {
    provider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      packages: findPackagesFrom(resourceProvider, getFolder('/test')),
      packageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
      nonPackageDefaultFeatureSet: FeatureSet.fromEnableFlags([]),
    );

    var featureSet = _getSdkFeatureSet('dart:math');
    expect(featureSet.isEnabled(Feature.non_nullable), isTrue);
  }

  void _assertNonNullableForPath(String path, bool expected) {
    var featureSet = _getPathFeatureSet(path);
    expect(featureSet.isEnabled(Feature.non_nullable), expected);
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

  FeatureSet _getSdkFeatureSet(String uriStr) {
    var uri = Uri.parse(uriStr);
    var path = sourceFactory.forUri2(uri).fullName;
    return provider.getFeatureSet(path, uri);
  }

  void _newSdkExperimentsFile(String content) {
    newFile('$sdkRoot/lib/_internal/allowed_experiments.json',
        content: content);
  }
}
