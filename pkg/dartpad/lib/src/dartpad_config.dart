// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show json;

/// Configuration for a _DartPad SDK_.
///
/// A _DartPad SDK_ is a folder consisting of:
///  * `sdk.tar`, files to be loaded into in-memory filesystem of the worker,
///  * `sdk.js`, precompiled Javascript DDC modules to be loaded into the
///    _sandboxed iframe_ before compiled code is executed.
///
/// For details, see `pkg/dartpad_worker/README.md`
final class DartPadConfig {
  /// Default location of the [DartPadConfig] file within an `sdk.tar`.
  static const defaultDartPadConfigPath = '/.dartpad_config.json';

  /// The path to the Dart SDK, defaults to `/sdk`, if not given.
  ///
  /// This is the Dart SDK, it is expected to contain at-least:
  ///  * `version`
  ///  * `lib/libraries.json`
  ///  * `lib/_internal/ddc_outline.dill`
  ///  * `lib/_internal/allowed_experiments.json`
  final String dartSdkPath;

  /// A map of summary .dill files to their required JS module names.
  ///
  /// **Example**
  /// ```js
  /// {'/sdk/flutter.dill': 'flutter_web', '/sdk/foo.dill': 'foo'}
  /// ```
  final Map<String, String> summaryModules;

  /// The run modes supported by this DartPad SDK.
  ///
  /// Each mode declares its name and optional `entrypointWrapperTemplate` which
  /// wraps the entrypoint.
  final List<DartPadRunMode> modes;

  /// The path to the Flutter SDK root, if flutter is available.
  ///
  /// This is the Flutter SDK, it is expected to contain at-least:
  ///  * `bin/cache/flutter.version.json`
  ///  * `bin/cache/flutter_web_sdk/kernel/flutter_web.dill`
  ///  * `bin/cache/pkg/sky_engine`
  ///  * `packages/flutter/`
  ///
  /// This is used to set the `FLUTTER_ROOT` environment variable.
  final String? flutterSdkPath;

  /// The `PUB_HOSTED_URL` environment variable, if not using `pub.dev`.
  ///
  /// This is used to set the `PUB_HOSTED_URL` environment variable when running
  /// `pub` commands.
  final String? pubHostedUrl;

  /// Whether or not to enable the trackCreationLocations DDC target flag.
  ///
  /// Defaults to `false`.
  final bool trackCreationLocations;

  DartPadConfig({
    this.dartSdkPath = '/sdk',
    this.summaryModules = const {},
    required this.modes,
    this.flutterSdkPath,
    this.pubHostedUrl,
    this.trackCreationLocations = false,
  });

  factory DartPadConfig.fromJson(Map<String, Object?> json) {
    return DartPadConfig(
      dartSdkPath: json['dartSdkPath'] as String? ?? '/sdk',
      summaryModules:
          (json['summaryModules'] as Map<String, Object?>?)
              ?.cast<String, String>() ??
          const {},
      modes:
          (json['modes'] as List<dynamic>?)
              ?.map((e) => DartPadRunMode.fromJson(e as Map<String, Object?>))
              .toList() ??
          const [],
      flutterSdkPath: json['flutterSdkPath'] as String?,
      pubHostedUrl: json['pubHostedUrl'] as String?,
      trackCreationLocations: json['trackCreationLocations'] as bool? ?? false,
    );
  }

  /// Create a [DartPadConfig] with overrides.
  DartPadConfig copyWith({
    String? dartSdkPath,
    Map<String, String>? summaryModules,
    List<DartPadRunMode>? modes,
    String? flutterSdkPath,
    String? pubHostedUrl,
    bool? trackCreationLocations,
  }) {
    return DartPadConfig(
      dartSdkPath: dartSdkPath ?? this.dartSdkPath,
      summaryModules: summaryModules ?? this.summaryModules,
      modes: modes ?? this.modes,
      flutterSdkPath: flutterSdkPath ?? this.flutterSdkPath,
      pubHostedUrl: pubHostedUrl ?? this.pubHostedUrl,
      trackCreationLocations:
          trackCreationLocations ?? this.trackCreationLocations,
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (dartSdkPath != '/sdk') 'dartSdkPath': dartSdkPath,
      if (summaryModules.isNotEmpty) 'summaryModules': summaryModules,
      if (modes.isNotEmpty) 'modes': modes.map((e) => e.toJson()).toList(),
      if (flutterSdkPath != null) 'flutterSdkPath': flutterSdkPath,
      if (pubHostedUrl != null) 'pubHostedUrl': pubHostedUrl,
      'trackCreationLocations': trackCreationLocations,
    };
  }

  @override
  String toString() => 'DartPadConfig(${json.encode(toJson())})';
}

/// Specifies a _run mode_ for a _DartPad SDK_.
///
/// A _DartPad SDK_ must declare the modes in which code can be executed.
/// A _run mode_ lets a _DartPad SDK_ modify how code is compiled and executed
/// without having to build and maintain a custom worker.
final class DartPadRunMode {
  /// Name that identifies the mode.
  ///
  /// This is what user will pass into `Sandbox.run(entrypoint, mode: ...)`.
  final String mode;

  /// The entrypoint wrapper template to use when compiling an entrypoint in
  /// this mode.
  ///
  /// When [entrypointWrapperTemplate] is not `null` and the compiler is asked
  /// to compile `<entrypoint>` it will instead:
  ///  * Create a virtual `<entrypoint>.virtual-bootstrap-wrapper.dart` file
  ///  * Write [entrypointWrapperTemplate] to this file.
  ///  * Replace occurences of `{{entrypoint}}` with `<entrypoint>`.
  ///  * Compile the virtual bootstrap wrapper file.
  ///
  /// This should typically be something like:
  /// ```dart
  /// import '{{entrypoint}}' as entrypoint;
  ///
  /// void main() {
  ///   entrypoint.main();
  /// }
  /// ```
  ///
  /// This is useful when compiling flutter apps, as it allows setup before
  /// invoking `entrypoint.main()`.
  final String? entrypointWrapperTemplate;

  DartPadRunMode({required this.mode, this.entrypointWrapperTemplate});

  factory DartPadRunMode.fromJson(Map<String, Object?> json) {
    return DartPadRunMode(
      mode: json['mode'] as String,
      entrypointWrapperTemplate: json['entrypointWrapperTemplate'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'mode': mode,
      if (entrypointWrapperTemplate != null)
        'entrypointWrapperTemplate': entrypointWrapperTemplate,
    };
  }

  @override
  String toString() => 'DartPadRunMode(${json.encode(toJson())})';
}
