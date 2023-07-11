// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/experiments/flags.dart' as shared;
import 'package:kernel/kernel.dart' show Version;

part 'experimental_flags_generated.dart';

/// The set of experiments enabled for SDK and packages.
///
/// This are derived from an `allowed_experiments.json` file whose default is
/// located in `sdk/lib/_internal/allowed_experiments.json`.
class AllowedExperimentalFlags {
  /// The set of experiments that are enabled for all SDK libraries other than
  /// for those which are specified in [sdkLibraryExperiments].
  final Set<ExperimentalFlag> sdkDefaultExperiments;

  /// Mapping from individual SDK libraries, e.g. 'core', to the set of
  /// experiments that are enabled for this library.
  final Map<String, Set<ExperimentalFlag>> sdkLibraryExperiments;

  /// Mapping from package names, e.g. 'path', to the set of experiments that
  /// are enabled for all files of this package.
  final Map<String, Set<ExperimentalFlag>> packageExperiments;

  const AllowedExperimentalFlags({
    this.sdkDefaultExperiments = const {},
    this.sdkLibraryExperiments = const {},
    this.packageExperiments = const {},
  });

  /// Return the set of enabled experiments for the package with the [name],
  /// e.g. "path", possibly `null`.
  Set<ExperimentalFlag>? forPackage(String name) {
    return packageExperiments[name];
  }

  /// Return the set of enabled experiments for the library with the [name],
  /// e.g. "core".
  Set<ExperimentalFlag> forSdkLibrary(String name) {
    return sdkLibraryExperiments[name] ?? sdkDefaultExperiments;
  }
}

/// Returns `true` if [flag] is enabled either by default or through
/// [explicitExperimentalFlags].
///
/// If [explicitExperimentalFlags] is `null` or doesn't contain [flag], the
/// default value from [defaultExperimentalFlags] is returned.
bool isExperimentEnabled(ExperimentalFlag flag,
    {Map<ExperimentalFlag, bool>? explicitExperimentalFlags,
    Map<ExperimentalFlag, bool>? defaultExperimentFlagsForTesting}) {
  bool? enabled;
  if (explicitExperimentalFlags != null) {
    enabled = explicitExperimentalFlags[flag];
  }
  if (defaultExperimentFlagsForTesting != null) {
    enabled ??= defaultExperimentFlagsForTesting[flag];
  }
  enabled ??= flag.isEnabledByDefault;
  return enabled;
}

/// Returns `true` if [flag] is enabled in the library with the [canonicalUri]
/// either globally using [explicitExperimentalFlags] or per library using
/// [allowedExperimentalFlags].
///
/// If [explicitExperimentalFlags] is `null` or doesn't contain [flag], the
/// default value from [defaultExperimentalFlags] used as the global flag state.
///
/// If [allowedExperimentalFlags] is `null` [defaultAllowedExperimentalFlags] is
/// used for the per library flag state.
///
/// The canonical uri, also known as the import uri, is the absolute uri that
/// defines the identity of a library, for instance `dart:core`, `package:foo`,
/// or `file:///path/dir/file.dart`.
bool isExperimentEnabledInLibrary(ExperimentalFlag flag, Uri canonicalUri,
    {Map<ExperimentalFlag, bool>? defaultExperimentFlagsForTesting,
    Map<ExperimentalFlag, bool>? explicitExperimentalFlags,
    AllowedExperimentalFlags? allowedExperimentalFlags}) {
  bool? enabled;
  if (explicitExperimentalFlags != null) {
    enabled = explicitExperimentalFlags[flag];
  }
  if (defaultExperimentFlagsForTesting != null) {
    enabled ??= defaultExperimentFlagsForTesting[flag];
  }
  enabled ??= flag.isEnabledByDefault;
  if (!enabled) {
    allowedExperimentalFlags ??= defaultAllowedExperimentalFlags;
    Set<ExperimentalFlag>? allowedFlags;
    if (canonicalUri.isScheme('dart')) {
      allowedFlags = allowedExperimentalFlags.forSdkLibrary(canonicalUri.path);
    } else if (canonicalUri.isScheme('package')) {
      int index = canonicalUri.path.indexOf('/');
      String packageName;
      if (index >= 0) {
        packageName = canonicalUri.path.substring(0, index);
      } else {
        packageName = canonicalUri.path;
      }
      allowedFlags = allowedExperimentalFlags.forPackage(packageName);
    }
    if (allowedFlags != null) {
      enabled = allowedFlags.contains(flag);
    }
  }
  return enabled;
}

/// Returns the version in which [flag] is enabled for the library with the
/// [canonicalUri].
Version getExperimentEnabledVersionInLibrary(ExperimentalFlag flag,
    Uri canonicalUri, Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    {AllowedExperimentalFlags? allowedExperimentalFlags,
    Map<ExperimentalFlag, bool>? defaultExperimentFlagsForTesting,
    Map<ExperimentalFlag, Version>? experimentEnabledVersionForTesting,
    Map<ExperimentalFlag, Version>? experimentReleasedVersionForTesting}) {
  allowedExperimentalFlags ??= defaultAllowedExperimentalFlags;

  Set<ExperimentalFlag>? allowedFlags;
  if (canonicalUri.isScheme('dart')) {
    allowedFlags = allowedExperimentalFlags.forSdkLibrary(canonicalUri.path);
  } else if (canonicalUri.isScheme('package')) {
    int index = canonicalUri.path.indexOf('/');
    String packageName;
    if (index >= 0) {
      packageName = canonicalUri.path.substring(0, index);
    } else {
      packageName = canonicalUri.path;
    }
    allowedFlags = allowedExperimentalFlags.forPackage(packageName);
  }
  Version? version;
  bool? enabledByDefault;
  if (defaultExperimentFlagsForTesting != null) {
    enabledByDefault = defaultExperimentFlagsForTesting[flag];
  }
  enabledByDefault ??= flag.isEnabledByDefault;

  bool enabledExplicitly = explicitExperimentalFlags[flag] ?? false;

  if (!enabledByDefault ||
      enabledExplicitly ||
      (allowedFlags != null && allowedFlags.contains(flag))) {
    // If the feature is not enabled by default or is enabled by the allowed
    // list use the experiment release version.
    if (experimentReleasedVersionForTesting != null) {
      version = experimentReleasedVersionForTesting[flag];
    }
    version ??= flag.experimentReleasedVersion;
  } else {
    // If the feature is enabled by default and is not enabled by the allowed
    // list use the enabled version.
    if (experimentEnabledVersionForTesting != null) {
      version = experimentEnabledVersionForTesting[flag];
    }
    version ??= flag.experimentEnabledVersion;
  }
  return version;
}

bool isExperimentEnabledInLibraryByVersion(
    ExperimentalFlag flag, Uri canonicalUri, Version version,
    {Map<ExperimentalFlag, bool>? defaultExperimentFlagsForTesting,
    required Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    AllowedExperimentalFlags? allowedExperimentalFlags,
    Map<ExperimentalFlag, Version>? experimentEnabledVersionForTesting,
    Map<ExperimentalFlag, Version>? experimentReleasedVersionForTesting}) {
  bool? enabledByDefault;
  if (defaultExperimentFlagsForTesting != null) {
    enabledByDefault = defaultExperimentFlagsForTesting[flag];
  }
  enabledByDefault ??= flag.isEnabledByDefault;

  bool enabledExplicitly = explicitExperimentalFlags[flag] ?? false;

  allowedExperimentalFlags ??= defaultAllowedExperimentalFlags;

  Set<ExperimentalFlag>? allowedFlags;
  bool enabledByAllowed = false;
  if (canonicalUri.isScheme('dart')) {
    allowedFlags = allowedExperimentalFlags.forSdkLibrary(canonicalUri.path);
  } else if (canonicalUri.isScheme('package')) {
    int index = canonicalUri.path.indexOf('/');
    String packageName;
    if (index >= 0) {
      packageName = canonicalUri.path.substring(0, index);
    } else {
      packageName = canonicalUri.path;
    }
    allowedFlags = allowedExperimentalFlags.forPackage(packageName);
  }
  if (allowedFlags != null) {
    enabledByAllowed = allowedFlags.contains(flag);
  }

  if (enabledByDefault || enabledExplicitly || enabledByAllowed) {
    // The feature is enabled depending on the library language version.
    Version? enabledVersion;
    if (!enabledByDefault || enabledExplicitly || enabledByAllowed) {
      // If the feature is not enabled by default or is enabled by the allowed
      // list, use the experiment release version.
      if (experimentReleasedVersionForTesting != null) {
        enabledVersion = experimentReleasedVersionForTesting[flag]!;
      }
      enabledVersion ??= flag.experimentReleasedVersion;
    } else {
      // If the feature is enabled by default and is not enabled by the allowed
      // list use the enabled version.
      if (experimentEnabledVersionForTesting != null) {
        enabledVersion = experimentEnabledVersionForTesting[flag];
      }
      enabledVersion ??= flag.experimentEnabledVersion;
    }
    return version >= enabledVersion;
  } else {
    // The feature is not enabled, regardless of library language version.
    return false;
  }
}

/// Common interface for the state of an experimental feature.
abstract class ExperimentalFeature {
  /// The flag for the experimental feature.
  final ExperimentalFlag flag;

  ExperimentalFeature(this.flag);

  /// `true` if this feature is enabled.
  bool get isEnabled;
}

/// The global state of an experimental feature.
class GlobalFeature extends ExperimentalFeature {
  @override
  final bool isEnabled;

  GlobalFeature(ExperimentalFlag flag, this.isEnabled) : super(flag);
}

/// The state of an experimental feature within a specific library.
class LibraryFeature extends ExperimentalFeature {
  /// `true` if this feature is supported in the library as defined by the
  /// default language version for its containing package/sdk.
  ///
  /// The feature might still not be enabled if the language version of the
  /// library itself is below the [enabledVersion] for the feature in the
  /// containing package/sdk.
  final bool isSupported;

  @override
  final bool isEnabled;

  /// The minimum language version for enabling this feature in this library.
  final Version enabledVersion;

  LibraryFeature(ExperimentalFlag flag, this.isSupported, this.enabledVersion,
      this.isEnabled)
      : super(flag);
}
