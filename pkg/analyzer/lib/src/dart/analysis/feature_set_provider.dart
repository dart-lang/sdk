// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

class FeatureSetProvider {
  /// This flag will be turned to `true` and inlined when we un-fork SDK,
  /// so that the only SDK is the Null Safe SDK.
  static const isNullSafetySdk = true;

  final AllowedExperiments _allowedExperiments;
  final Packages _packages;
  final FeatureSet _packageDefaultFeatureSet;
  final FeatureSet _nonPackageDefaultFeatureSet;

  FeatureSetProvider._({
    @required AllowedExperiments allowedExperiments,
    @required Packages packages,
    @required FeatureSet packageDefaultFeatureSet,
    @required FeatureSet nonPackageDefaultFeatureSet,
  })  : _allowedExperiments = allowedExperiments,
        _packages = packages,
        _packageDefaultFeatureSet = packageDefaultFeatureSet,
        _nonPackageDefaultFeatureSet = nonPackageDefaultFeatureSet;

  /// Return the [FeatureSet] for the Dart file with the given [uri].
  FeatureSet getFeatureSet(String path, Uri uri) {
    if (uri.isScheme('dart')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var libraryName = pathSegments.first;
        var experiments = _allowedExperiments.forSdkLibrary(libraryName);
        return FeatureSet.fromEnableFlags(experiments);
      } else {
        return FeatureSet.fromEnableFlags([]);
      }
    }

    if (uri.isScheme('package')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var packageName = pathSegments.first;
        var experiments = _allowedExperiments.forPackage(packageName);
        if (experiments != null) {
          return FeatureSet.fromEnableFlags(experiments);
        }
      }
    }

    var package = _packages.packageForPath(path);
    if (package != null) {
      var languageVersion = package.languageVersion;
      languageVersion ??= ExperimentStatus.currentVersion;
      return _packageDefaultFeatureSet.restrictToVersion(languageVersion);
    }

    return _nonPackageDefaultFeatureSet;
  }

  /// Return the language version configured for the file.
  Version getLanguageVersion(String path, Uri uri) {
    var package = _packages.packageForPath(path);
    if (package != null) {
      var languageVersion = package.languageVersion;
      if (languageVersion != null) {
        return languageVersion;
      }
    }

    return ExperimentStatus.currentVersion;
  }

  static FeatureSetProvider build({
    @required SourceFactory sourceFactory,
    @required Packages packages,
    @required FeatureSet packageDefaultFeatureSet,
    @required FeatureSet nonPackageDefaultFeatureSet,
  }) {
    var allowedExperiments = _experimentsForSdk(sourceFactory.dartSdk);
    return FeatureSetProvider._(
      allowedExperiments: allowedExperiments,
      packages: packages,
      packageDefaultFeatureSet: packageDefaultFeatureSet,
      nonPackageDefaultFeatureSet: nonPackageDefaultFeatureSet,
    );
  }

  static AllowedExperiments _experimentsForSdk(DartSdk sdk) {
    var experimentsContent = sdk.allowedExperimentsJson;
    if (experimentsContent != null) {
      try {
        return parseAllowedExperiments(experimentsContent);
      } catch (_) {}
    }

    return AllowedExperiments(
      sdkDefaultExperiments: [],
      sdkLibraryExperiments: {},
      packageExperiments: {},
    );
  }
}
