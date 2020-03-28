// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

class FeatureSetProvider {
  /// This flag will be turned to `true` and inlined when we un-fork SDK,
  /// so that the only SDK is the Null Safe SDK.
  static const isNullSafetySdk = true;

  final FeatureSet _sdkFeatureSet;
  final Packages _packages;
  final FeatureSet _packageDefaultFeatureSet;
  final FeatureSet _nonPackageDefaultFeatureSet;

  FeatureSetProvider._({
    FeatureSet sdkFeatureSet,
    Packages packages,
    FeatureSet packageDefaultFeatureSet,
    FeatureSet nonPackageDefaultFeatureSet,
  })  : _sdkFeatureSet = sdkFeatureSet,
        _packages = packages,
        _packageDefaultFeatureSet = packageDefaultFeatureSet,
        _nonPackageDefaultFeatureSet = nonPackageDefaultFeatureSet;

  /// Return the [FeatureSet] for the Dart file with the given [uri].
  FeatureSet getFeatureSet(String path, Uri uri) {
    if (uri.isScheme('dart')) {
      return _sdkFeatureSet;
    }

    for (var package in _packages.packages) {
      if (package.rootFolder.contains(path)) {
        var languageVersion = package.languageVersion;
        if (languageVersion == null ||
            languageVersion == ExperimentStatus.currentVersion) {
          return _packageDefaultFeatureSet;
        } else {
          return _packageDefaultFeatureSet.restrictToVersion(languageVersion);
        }
      }
    }

    return _nonPackageDefaultFeatureSet;
  }

  /// Return the language version configured for the file.
  Version getLanguageVersion(String path, Uri uri) {
    for (var package in _packages.packages) {
      if (package.rootFolder.contains(path)) {
        var languageVersion = package.languageVersion;
        if (languageVersion != null) {
          return languageVersion;
        }
        break;
      }
    }

    return ExperimentStatus.currentVersion;
  }

  static FeatureSetProvider build({
    @required ResourceProvider resourceProvider,
    @required Packages packages,
    @required FeatureSet packageDefaultFeatureSet,
    @required FeatureSet nonPackageDefaultFeatureSet,
  }) {
    var sdkFeatureSet = FeatureSet.fromEnableFlags(['non-nullable']);

    return FeatureSetProvider._(
      sdkFeatureSet: sdkFeatureSet,
      packages: packages,
      packageDefaultFeatureSet: packageDefaultFeatureSet,
      nonPackageDefaultFeatureSet: nonPackageDefaultFeatureSet,
    );
  }
}
