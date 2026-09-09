// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Resolves the Flutter project's minimum OS deployment targets from the file
/// system — specifically from `ios/Podfile`, `macos/Podfile`, and
/// `project.pbxproj` files.
library;

import 'dart:io';
import 'package:path/path.dart' as p;

/// Supported Apple platforms.
enum ApplePlatform {
  /// Apple iOS (iPhone, iPad).
  ios,

  /// Apple macOS (desktop).
  macos,

  /// Apple tvOS.
  tvos,

  /// Apple watchOS.
  watchos,

  /// Apple visionOS.
  visionos;

  /// The directory name used for this platform in a Flutter project.
  String get flutterDir => name; // 'ios', 'macos', etc.

  /// The `IPHONEOS_DEPLOYMENT_TARGET` / `MACOSX_DEPLOYMENT_TARGET` key in
  /// project.pbxproj.
  String get pbxprojKey => switch (this) {
        ApplePlatform.ios => 'IPHONEOS_DEPLOYMENT_TARGET',
        ApplePlatform.macos => 'MACOSX_DEPLOYMENT_TARGET',
        ApplePlatform.tvos => 'TVOS_DEPLOYMENT_TARGET',
        ApplePlatform.watchos => 'WATCHOS_DEPLOYMENT_TARGET',
        ApplePlatform.visionos => 'XROS_DEPLOYMENT_TARGET',
      };

  /// The Podfile `platform` identifier used for this platform.
  String get podfilePlatform => switch (this) {
        ApplePlatform.ios => ':ios',
        ApplePlatform.macos => ':osx',
        ApplePlatform.tvos => ':tvos',
        ApplePlatform.watchos => ':watchos',
        ApplePlatform.visionos => ':visionos',
      };
}

/// Resolves deployment targets for a Flutter project rooted at [projectRoot].
///
/// Resolution order (first match wins):
///  1. `{platform}/Podfile`  — `platform :ios, '14.0'`
///  2. `{platform}/Runner.xcodeproj/project.pbxproj` — `IPHONEOS_DEPLOYMENT_TARGET = 14.0`
///
/// Callers may also use [withOverrides] to apply values read from
/// `analysis_options.yaml` as the highest-priority source.
class DeploymentTargetResolver {
  final String projectRoot;

  /// Optional overrides from `analysis_options.yaml`.
  /// Keys are lowercase platform names matching [ApplePlatform.name].
  final Map<String, String> _overrides;

  // Cache: platform -> version string.
  final Map<ApplePlatform, String?> _cache = {};

  DeploymentTargetResolver(
    this.projectRoot, {
    Map<String, String> overrides = const {},
  }) : _overrides = overrides;

  /// Returns the minimum deployment target for [platform], or `null` if it
  /// cannot be determined.
  ///
  /// Result is cached after the first call per platform.
  String? resolve(ApplePlatform platform) {
    return _cache.putIfAbsent(platform, () => _resolve(platform));
  }

  String? _resolve(ApplePlatform platform) {
    // 1. analysis_options.yaml override (highest priority).
    if (_overrides.containsKey(platform.name)) {
      return _overrides[platform.name];
    }

    // 2. Podfile.
    final podfileVersion = _resolvePodfile(platform);
    if (podfileVersion != null) return podfileVersion;

    // 3. project.pbxproj.
    final pbxVersion = _resolvePbxproj(platform);
    if (pbxVersion != null) return pbxVersion;

    return null;
  }

  /// Parses the Podfile for the given [platform].
  ///
  /// Looks for lines matching:
  ///   `platform :ios, '14.0'`
  String? _resolvePodfile(ApplePlatform platform) {
    final podfilePath = p.join(projectRoot, platform.flutterDir, 'Podfile');
    final file = File(podfilePath);
    if (!file.existsSync()) return null;

    // Match: platform :ios, 'X.Y' or platform :ios, "X.Y"
    // The platform identifier varies: :ios, :osx, :tvos, etc.
    final platformKey = RegExp.escape(platform.podfilePlatform);
    final pattern = RegExp(
      r'''^\s*platform\s+''' + platformKey + r'''\s*,\s*['"]([0-9]+(?:\.[0-9]+)*)['"]''',
      multiLine: true,
    );

    final content = file.readAsStringSync();
    final match = pattern.firstMatch(content);
    return match?.group(1);
  }

  /// Parses the Xcode project.pbxproj for the given [platform].
  ///
  /// Looks for lines matching:
  ///   `IPHONEOS_DEPLOYMENT_TARGET = 14.0;`
  String? _resolvePbxproj(ApplePlatform platform) {
    final pbxprojPath = p.join(
      projectRoot,
      platform.flutterDir,
      'Runner.xcodeproj',
      'project.pbxproj',
    );
    final file = File(pbxprojPath);
    if (!file.existsSync()) return null;

    final key = RegExp.escape(platform.pbxprojKey);
    // Match: IPHONEOS_DEPLOYMENT_TARGET = 14.0;
    // May appear multiple times (per build config); collect all and take min.
    final pattern = RegExp(
      r'^\s*' + key + r'\s*=\s*([0-9]+(?:\.[0-9]+)*)\s*;',
      multiLine: true,
    );

    final content = file.readAsStringSync();
    final versions = pattern
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();

    if (versions.isEmpty) return null;

    // Use the minimum version found across all build configurations — this is
    // the most conservative (safest) choice.
    return versions.reduce(_minVersion);
  }

  /// Returns the smaller of two version strings, comparing numerically.
  static String _minVersion(String a, String b) =>
      _versionValue(a) <= _versionValue(b) ? a : b;

  /// Converts a version string like `'14.2'` to a comparable double.
  static double _versionValue(String v) {
    final parts = v.split('.').map(int.tryParse).toList();
    if (parts.isEmpty || parts[0] == null) return 0;
    final major = parts[0]!;
    final minor = parts.length > 1 ? (parts[1] ?? 0) : 0;
    return major + minor / 100.0;
  }
}

/// Parses `native_api_lint` plugin configuration from an
/// `analysis_options.yaml` value map.
///
/// Expected YAML structure:
/// ```yaml
/// analyzer:
///   plugins:
///     native_api_lint:
///
/// native_api_lint:
///   ios_min: '14.0'
///   macos_min: '11.0'
/// ```
///
/// Returns a `Map<String, String>` suitable for passing to
/// [DeploymentTargetResolver] as `overrides`.
Map<String, String> parseAnalysisOptionsOverrides(
  Map<Object, Object?> pluginOptions,
) {
  final result = <String, String>{};
  for (final platform in ApplePlatform.values) {
    final key = '${platform.name}_min';
    final value = pluginOptions[key];
    if (value is String && value.isNotEmpty) {
      result[platform.name] = value;
    }
  }
  return result;
}
