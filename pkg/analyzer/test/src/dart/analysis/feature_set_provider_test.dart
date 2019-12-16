// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
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

  test_jsonConfig_defaultNonNullable() {
    var jsonConfigPath = '/test/.dart_tool/package_config.json';
    var jsonConfigFile = newFile(jsonConfigPath, content: '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    },
    {
      "name": "aaa",
      "rootUri": "${toUriStr('/packages/aaa')}",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    },
    {
      "name": "bbb",
      "rootUri": "${toUriStr('/packages/bbb')}",
      "packageUri": "lib/"
    }
  ]
}
''');

    var packages = parsePackageConfigJsonFile(
      resourceProvider,
      jsonConfigFile,
    );
    _createSourceFactory(
      packageUriResolver: _createPackageMapUriResolver(packages),
    );

    _simulateNonNullableSdk();
    _buildProvider(['non-nullable']);

    _assertNonNullableForPath('/test/a.dart', true);
    _assertNonNullableForPath('/test/lib/b.dart', true);
    _assertNonNullableForPath('/test/test/c.dart', true);

    _assertNonNullableForPath('/packages/aaa/a.dart', false);
    _assertNonNullableForPath('/packages/aaa/lib/b.dart', false);
    _assertNonNullableForPath('/packages/aaa/test/c.dart', false);

    _assertNonNullableForPath('/packages/bbb/a.dart', true);
    _assertNonNullableForPath('/packages/bbb/lib/b.dart', true);
    _assertNonNullableForPath('/packages/bbb/test/c.dart', true);

    _assertNonNullableForPath('/other/file.dart', true);
  }

  test_sdk_defaultLegacy_sdkLegacy() {
    newFile('/test/.packages', content: '''
test:lib/
''');
    _simulateLegacySdk();
    _buildProvider([]);

    var featureSet = _getSdkFeatureSet();
    expect(featureSet.isEnabled(Feature.non_nullable), isFalse);
  }

  test_sdk_defaultNonNullable_sdkLegacy() {
    newFile('/test/.packages', content: '''
test:lib/
''');
    _simulateLegacySdk();
    _buildProvider(['non-nullable']);

    var featureSet = _getSdkFeatureSet();
    expect(featureSet.isEnabled(Feature.non_nullable), isFalse);
  }

  test_sdk_defaultNonNullable_sdkNonNullable() {
    newFile('/test/.packages', content: '''
test:lib/
''');
    _simulateNonNullableSdk();
    _buildProvider(['non-nullable']);

    var featureSet = _getSdkFeatureSet();
    expect(featureSet.isEnabled(Feature.non_nullable), isTrue);
  }

  void _assertNonNullableForPath(String path, bool expected) {
    var featureSet = _getPathFeatureSet(path);
    expect(featureSet.isEnabled(Feature.non_nullable), expected);
  }

  void _buildProvider(List<String> enabledExperiments) {
    provider = FeatureSetProvider.build(
      resourceProvider: resourceProvider,
      contextRoot: ContextRoot(
        convertPath('/test'),
        [],
        pathContext: resourceProvider.pathContext,
      ),
      sourceFactory: sourceFactory,
      defaultFeatureSet: FeatureSet.fromEnableFlags(enabledExperiments),
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

  void _replaceDartCoreObject(String content) {
    var path = sourceFactory.forUri('dart:core').fullName;
    newFile(path, content: content);
  }

  void _simulateLegacySdk() {
    _replaceDartCoreObject('// no marker');
  }

  void _simulateNonNullableSdk() {
    _replaceDartCoreObject('// bool operator ==(Object other)');
  }
}
