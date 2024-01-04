// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:extension_discovery/extension_discovery.dart';
import 'package:path/path.dart' as path;

class VsCodeExtensionsManager {
  /// Reads metadata about the VS Code extensions for the packages used by the
  /// project at [rootPath].
  Future<VsCodeExtensionResults> findVsCodeExtensions(String rootPath) async {
    const targetName = 'vs_code';
    final packageConfig =
        Uri.file(path.join(rootPath, '.dart_tool', 'package_config.json'));
    final results = VsCodeExtensionResults();

    try {
      final extensions = await findExtensions(
        targetName,
        packageConfig: packageConfig,
      );

      for (final extension in extensions) {
        try {
          results.extensions.add(
            VsCodeExtensionConfig.parse(extension.package, extension.config),
          );
        } on Error catch (e) {
          results.parseErrors.add(VsCodeExtensionParseError(
              packageName: extension.package, error: e.toString()));
        }
      }
    } on PackageConfigException {
      // If the package_config doesn't exist or is invalid, we'll just return
      // the empty results.
    }

    return results;
  }
}

class VsCodeExtensionResults {
  final extensions = <VsCodeExtensionConfig>[];
  final parseErrors = <VsCodeExtensionParseError>[];

  Map<String, Object?> toJson() => {
        'extensions': extensions,
        'parseErrors': parseErrors,
      };
}

class VsCodeExtensionParseError {
  VsCodeExtensionParseError({required this.packageName, required this.error});

  final String packageName;
  final String error;

  Map<String, Object?> toJson() => {
        'packageName': packageName,
        'error': error,
      };
}

class VsCodeExtensionConfig {
  VsCodeExtensionConfig._({
    required this.packageName,
    required this.vsCodeExtensionId,
  });

  factory VsCodeExtensionConfig.parse(
    String packageName,
    Map<String, Object?> json,
  ) {
    if (json
        case {
          vsCodeExtensionIdKey: final String vsCodeExtensionId,
        }) {
      return VsCodeExtensionConfig._(
        packageName: packageName,
        vsCodeExtensionId: vsCodeExtensionId,
      );
    } else {
      const requiredKeysFromConfigFile = <String>{
        vsCodeExtensionIdKey,
      };

      final missing = requiredKeysFromConfigFile.difference(json.keys.toSet());

      if (missing.isNotEmpty) {
        throw StateError(
          'Missing required fields $missing in the extension '
          'config.yaml.',
        );
      } else {
        // All the required keys are present, but the value types did not match.
        final sb = StringBuffer();
        for (final entry in json.entries) {
          sb.writeln(
            '   ${entry.key}: ${entry.value} (${entry.value.runtimeType})',
          );
        }
        throw StateError(
          'Unexpected value types in the extension config.yaml. Expected all '
          'values to be of type String, but one or more had a different type:\n'
          '$sb',
        );
      }
    }
  }

  Map<String, Object?> toJson() => {
        'packageName': packageName,
        VsCodeExtensionConfig.vsCodeExtensionIdKey: vsCodeExtensionId,
      };

  /// The YAML key for the ID of the VS Code extension.
  ///
  /// This is 'extension' in the YAML because users have to type it and it's
  /// already in a VS-Code-specific file, but in code we use a more descriptive
  /// name.
  static const vsCodeExtensionIdKey = 'extension';

  /// The name of the package promoting the extension.
  final String packageName;

  /// The ID of the VS Code extension being promoted.
  ///
  /// The format should be 'publisher.extension' matching what's shown inside
  /// VS Code and on the market place.
  final String vsCodeExtensionId;
}
