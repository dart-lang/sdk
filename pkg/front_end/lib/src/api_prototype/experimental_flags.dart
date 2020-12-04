// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    this.sdkDefaultExperiments: const {},
    this.sdkLibraryExperiments: const {},
    this.packageExperiments: const {},
  });

  /// Return the set of enabled experiments for the package with the [name],
  /// e.g. "path", possibly `null`.
  Set<ExperimentalFlag> forPackage(String name) {
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
///
/// If [flag] is marked as expired in [expiredExperimentalFlags], the value from
/// [defaultExperimentalFlags] is always returned.
bool isExperimentEnabled(ExperimentalFlag flag,
    {Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    Map<ExperimentalFlag, bool> defaultExperimentFlagsForTesting}) {
  assert(defaultExperimentalFlags.containsKey(flag),
      "No default value for $flag.");
  assert(expiredExperimentalFlags.containsKey(flag),
      "No expired value for $flag.");
  if (expiredExperimentalFlags[flag]) {
    return defaultExperimentalFlags[flag];
  }
  bool enabled;
  if (explicitExperimentalFlags != null) {
    enabled = explicitExperimentalFlags[flag];
  }
  if (defaultExperimentFlagsForTesting != null) {
    enabled ??= defaultExperimentFlagsForTesting[flag];
  }
  enabled ??= defaultExperimentalFlags[flag];
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
/// If [flag] is marked as expired in [expiredExperimentalFlags], the value from
/// [defaultExperimentalFlags] is always returned.
///
/// The canonical uri, also known as the import uri, is the absolute uri that
/// defines the identity of a library, for instance `dart:core`, `package:foo`,
/// or `file:///path/dir/file.dart`.
bool isExperimentEnabledInLibrary(ExperimentalFlag flag, Uri canonicalUri,
    {Map<ExperimentalFlag, bool> defaultExperimentFlagsForTesting,
    Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    AllowedExperimentalFlags allowedExperimentalFlags}) {
  assert(defaultExperimentalFlags.containsKey(flag),
      "No default value for $flag.");
  assert(expiredExperimentalFlags.containsKey(flag),
      "No expired value for $flag.");
  if (expiredExperimentalFlags[flag]) {
    return defaultExperimentalFlags[flag];
  }
  bool enabled;
  if (explicitExperimentalFlags != null) {
    enabled = explicitExperimentalFlags[flag];
  }
  if (defaultExperimentFlagsForTesting != null) {
    enabled ??= defaultExperimentFlagsForTesting[flag];
  }
  enabled ??= defaultExperimentalFlags[flag];
  if (!enabled) {
    allowedExperimentalFlags ??= defaultAllowedExperimentalFlags;
    Set<ExperimentalFlag> allowedFlags;
    if (canonicalUri.scheme == 'dart') {
      allowedFlags = allowedExperimentalFlags.forSdkLibrary(canonicalUri.path);
    } else if (canonicalUri.scheme == 'package') {
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
    {AllowedExperimentalFlags allowedExperimentalFlags,
    Map<ExperimentalFlag, bool> defaultExperimentFlagsForTesting,
    Map<ExperimentalFlag, Version> experimentEnabledVersionForTesting,
    Map<ExperimentalFlag, Version> experimentReleasedVersionForTesting}) {
  allowedExperimentalFlags ??= defaultAllowedExperimentalFlags;

  Set<ExperimentalFlag> allowedFlags;
  if (canonicalUri.scheme == 'dart') {
    allowedFlags = allowedExperimentalFlags.forSdkLibrary(canonicalUri.path);
  } else if (canonicalUri.scheme == 'package') {
    int index = canonicalUri.path.indexOf('/');
    String packageName;
    if (index >= 0) {
      packageName = canonicalUri.path.substring(0, index);
    } else {
      packageName = canonicalUri.path;
    }
    allowedFlags = allowedExperimentalFlags.forPackage(packageName);
  }
  Version version;
  bool enabledByDefault;
  if (defaultExperimentFlagsForTesting != null) {
    enabledByDefault = defaultExperimentFlagsForTesting[flag];
  }
  enabledByDefault ??= defaultExperimentalFlags[flag];

  bool enabledExplicitly = explicitExperimentalFlags[flag] ?? false;

  if (!enabledByDefault ||
      enabledExplicitly ||
      (allowedFlags != null && allowedFlags.contains(flag))) {
    // If the feature is not enabled by default or is enabled by the allowed
    // list use the experiment release version.
    if (experimentReleasedVersionForTesting != null) {
      version = experimentReleasedVersionForTesting[flag];
    }
    version ??= experimentReleasedVersion[flag];
  } else {
    // If the feature is enabled by default and is not enabled by the allowed
    // list use the enabled version.
    if (experimentEnabledVersionForTesting != null) {
      version = experimentEnabledVersionForTesting[flag];
    }
    version ??= experimentEnabledVersion[flag];
  }
  assert(version != null, "No version for enabling $flag in $canonicalUri.");
  return version;
}
