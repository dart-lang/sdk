// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

class FeatureSetProvider {
  /// This flag will be turned to `true` and inlined when we un-fork SDK,
  /// so that the only SDK is the Null Safe SDK.
  static const isNullSafetySdk = false;

  static final _preNonNullableVersion = Version(2, 7, 0);

  final FeatureSet _sdkFeatureSet;
  final Packages _packages;
  final FeatureSet _defaultFeatureSet;

  FeatureSetProvider._({
    FeatureSet sdkFeatureSet,
    Packages packages,
    FeatureSet defaultFeatureSet,
  })  : _sdkFeatureSet = sdkFeatureSet,
        _packages = packages,
        _defaultFeatureSet = defaultFeatureSet;

  /// Return the [FeatureSet] for the Dart file with the given [uri].
  FeatureSet getFeatureSet(String path, Uri uri) {
    if (uri.isScheme('dart')) {
      return _sdkFeatureSet;
    }

    for (var package in _packages.packages) {
      if (package.rootFolder.contains(path)) {
        var languageVersion = package.languageVersion;
        if (languageVersion == null) {
          _defaultFeatureSet;
        } else {
          return _defaultFeatureSet.restrictToVersion(languageVersion);
        }
      }
    }

    return _defaultFeatureSet;
  }

  static FeatureSetProvider build({
    @required ResourceProvider resourceProvider,
    @required ContextRoot contextRoot,
    @required SourceFactory sourceFactory,
    @required FeatureSet defaultFeatureSet,
  }) {
    var sdkFeatureSet = _determineSdkFeatureSet(
      resourceProvider,
      sourceFactory,
      defaultFeatureSet,
    );

    var packages = _findPackages(resourceProvider, contextRoot);

    return FeatureSetProvider._(
      sdkFeatureSet: sdkFeatureSet,
      packages: packages,
      defaultFeatureSet: defaultFeatureSet,
    );
  }

  /// Read `dart:core` file and determine if SDK in non-nullable by default.
  ///
  /// If it is, use the [defaultFeatureSet], which might have enabled
  /// [Feature.non_nullable], so SDK will be parsed and resolved as
  /// non-nullable.
  ///
  /// Otherwise, restrict the SDK language to the maximum known now.
  static FeatureSet _determineSdkFeatureSet(
    ResourceProvider resourceProvider,
    SourceFactory sourceFactory,
    FeatureSet defaultFeatureSet,
  ) {
    var objectSource = sourceFactory.forUri('dart:core/object.dart');
    if (objectSource == null) {
      objectSource = sourceFactory.forUri('dart:core');
    }

    try {
      var objectFile = resourceProvider.getFile(objectSource.fullName);
      var objectContent = objectFile.readAsStringSync();
      if (!objectContent.contains('bool operator ==(Object other)')) {
        return defaultFeatureSet.restrictToVersion(_preNonNullableVersion);
      }
    } catch (_) {}

    return defaultFeatureSet;
  }

  static Packages _findPackages(
    ResourceProvider resourceProvider,
    ContextRoot contextRoot,
  ) {
    if (contextRoot == null) {
      return Packages(const {});
    }

    var rootFolder = resourceProvider.getFolder(contextRoot.root);
    return findPackagesFrom(resourceProvider, rootFolder);
  }
}
