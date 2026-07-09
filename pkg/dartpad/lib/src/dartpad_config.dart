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

  /// The bootstrap code template to use when compiling.
  ///
  /// When [bootstrapCode] is not `null` and the compiler is asked to compile
  /// `<entrypoint>` it will instead:
  ///  * Create a virtual `<entrypoint>.virtual-bootstrap-wrapper.dart` file
  ///  * Write [bootstrapCode] to this file.
  ///  * Replace occurences of `{{entrypoint}}` with `<entrypoint>`.
  ///  * Compile the virtual bootstrap wrapper file.
  ///
  /// This is useful when compiling flutter apps.
  final String? bootstrapCode;

  /// The path to the Flutter SDK root, if flutter is available.
  ///
  /// This is the Flutter SDK, it is expected to contain at-least:
  ///  * `bin/cache/flutter.version.json`
  ///  * `bin/cache/flutter_web_sdk/kernel/flutter_web.dill`
  ///  * `bin/cache/pkg/sky_engine`
  ///  * `packages/flutter/`
  ///
  /// This is used to set the `FLUTTER_ROOT` environment variable.
  ///
  ///
  final String? flutterSdkPath;

  /// The `PUB_HOSTED_URL` environment variable, if not using `pub.dev`.
  ///
  /// This is used to set the `PUB_HOSTED_URL` environment variable when running
  /// `pub` commands.
  final String? pubHostedUrl;

  DartPadConfig({
    this.dartSdkPath = '/sdk',
    this.summaryModules = const {},
    this.bootstrapCode,
    this.flutterSdkPath,
    this.pubHostedUrl,
  });

  factory DartPadConfig.fromJson(Map<String, Object?> json) {
    return DartPadConfig(
      dartSdkPath: json['dartSdkPath'] as String? ?? '/sdk',
      summaryModules:
          (json['summaryModules'] as Map<String, Object?>?)
              ?.cast<String, String>() ??
          const {},
      bootstrapCode: json['bootstrapCode'] as String?,
      flutterSdkPath: json['flutterSdkPath'] as String?,
      pubHostedUrl: json['pubHostedUrl'] as String?,
    );
  }

  /// Create a [DartPadConfig] with overrides.
  DartPadConfig copyWith({
    String? dartSdkPath,
    Map<String, String>? summaryModules,
    String? bootstrapCode,
    String? flutterSdkPath,
    String? pubHostedUrl,
  }) {
    return DartPadConfig(
      dartSdkPath: dartSdkPath ?? this.dartSdkPath,
      summaryModules: summaryModules ?? this.summaryModules,
      bootstrapCode: bootstrapCode ?? this.bootstrapCode,
      flutterSdkPath: flutterSdkPath ?? this.flutterSdkPath,
      pubHostedUrl: pubHostedUrl ?? this.pubHostedUrl,
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (dartSdkPath != '/sdk') 'dartSdkPath': dartSdkPath,
      if (summaryModules.isNotEmpty) 'summaryModules': summaryModules,
      if (bootstrapCode != null) 'bootstrapCode': bootstrapCode,
      if (flutterSdkPath != null) 'flutterSdkPath': flutterSdkPath,
      if (pubHostedUrl != null) 'pubHostedUrl': pubHostedUrl,
    };
  }

  @override
  String toString() => 'DartPadConfig(${json.encode(toJson())})';
}
