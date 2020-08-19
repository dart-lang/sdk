// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

class FeatureSetProvider {
  /// This flag will be turned to `true` and inlined when we un-fork SDK,
  /// so that the only SDK is the Null Safe SDK.
  static const isNullSafetySdk = true;

  final Version _sdkLanguageVersion;
  final AllowedExperiments _allowedExperiments;
  final ResourceProvider _resourceProvider;
  final Packages _packages;
  final FeatureSet _packageDefaultFeatureSet;
  final FeatureSet _nonPackageDefaultFeatureSet;

  FeatureSetProvider._({
    @required Version sdkLanguageVersion,
    @required AllowedExperiments allowedExperiments,
    @required ResourceProvider resourceProvider,
    @required Packages packages,
    @required FeatureSet packageDefaultFeatureSet,
    @required FeatureSet nonPackageDefaultFeatureSet,
  })  : _sdkLanguageVersion = sdkLanguageVersion,
        _allowedExperiments = allowedExperiments,
        _resourceProvider = resourceProvider,
        _packages = packages,
        _packageDefaultFeatureSet = packageDefaultFeatureSet,
        _nonPackageDefaultFeatureSet = nonPackageDefaultFeatureSet;

  FeatureSet featureSetForExperiments(List<String> experiments) {
    if (experiments == null) {
      return null;
    }

    return FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: _sdkLanguageVersion,
      flags: experiments,
    );
  }

  /// Return the [FeatureSet] for the package that contains the file.
  FeatureSet getFeatureSet(String path, Uri uri) {
    if (uri.isScheme('dart')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var libraryName = pathSegments.first;
        var experiments = _allowedExperiments.forSdkLibrary(libraryName);
        return featureSetForExperiments(experiments);
      } else {
        return featureSetForExperiments([]);
      }
    }

    var package = _findPackage(uri, path);
    if (package != null) {
      var experiments = _allowedExperiments.forPackage(package.name);
      if (experiments != null) {
        return featureSetForExperiments(experiments);
      }

      return _packageDefaultFeatureSet;
    }

    return _nonPackageDefaultFeatureSet;
  }

  /// Return the language version for the package that contains the file.
  ///
  /// Each individual file might use `// @dart` to override this version, to
  /// be either lower, or higher than the package language version.
  Version getLanguageVersion(String path, Uri uri) {
    if (uri.isScheme('dart')) {
      return ExperimentStatus.currentVersion;
    }
    var package = _findPackage(uri, path);
    if (package != null) {
      var languageVersion = package.languageVersion;
      if (languageVersion != null) {
        return languageVersion;
      }
    }

    return ExperimentStatus.currentVersion;
  }

  /// Return the package corresponding to the [uri] or [path], `null` if none.
  Package _findPackage(Uri uri, String path) {
    if (uri.isScheme('package')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var packageName = pathSegments.first;
        var package = _packages[packageName];
        if (package != null) {
          return package;
        }
      }
    } else if (uri.isScheme('file')) {
      var uriPath = fileUriToNormalizedPath(_resourceProvider.pathContext, uri);
      var package = _packages.packageForPath(uriPath);
      if (package != null) {
        return package;
      }
    }

    return _packages.packageForPath(path);
  }

  static FeatureSetProvider build({
    @required SourceFactory sourceFactory,
    @required ResourceProvider resourceProvider,
    @required Packages packages,
    @required FeatureSet packageDefaultFeatureSet,
    @required FeatureSet nonPackageDefaultFeatureSet,
  }) {
    var sdk = sourceFactory.dartSdk;
    var allowedExperiments = _experimentsForSdk(sdk);
    return FeatureSetProvider._(
      sdkLanguageVersion: sdk.languageVersion,
      allowedExperiments: allowedExperiments,
      resourceProvider: resourceProvider,
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
