// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

const String _defaultVersionConstraint = 'any';
const String _evalWorkspaceName = 'dart_eval_workspace';

final RegExp _sdkVersionRegExp = RegExp(r'^(\d+\.\d+\.\d+)');

/// Manages resolution of package dependencies for `dart -e` evaluation.
abstract final class EvalPackageResolver {
  /// Extracts non-core package names imported in the code snippet using the analyzer AST parser.
  static Set<String> extractPackageImports(String code) {
    final packages = <String>{};
    final unit = parseString(
      content: code,
      throwIfDiagnostics: false,
    ).unit;
    for (final directive in unit.directives) {
      if (directive is ImportDirective) {
        final uriString = directive.uri.stringValue;
        if (uriString != null) {
          final pkgName = Uri.tryParse(uriString)?.packageName;
          if (pkgName != null) {
            packages.add(pkgName);
          }
        }
      }
    }
    return packages;
  }

  /// Merges package dependencies from auto-imports and `-P` / `--package-constraint` CLI flags.
  static Map<String, String> collectDependencies(
    String code, {
    List<String>? packages,
  }) {
    final deps = <String, String>{};

    // 1. Auto-detected package imports from code snippet
    for (final pkg in extractPackageImports(code)) {
      deps[pkg] = _defaultVersionConstraint;
    }

    // 2. CLI -P / --package-constraint flags (e.g. ["http:^1.2.0", "path"])
    if (packages != null) {
      for (final spec in packages) {
        if (spec.trim().isEmpty) continue;
        final parts = spec.split(':');
        final pkg = parts[0].trim();
        final version = parts.length > 1
            ? parts.sublist(1).join(':').trim()
            : _defaultVersionConstraint;
        if (pkg.isNotEmpty) {
          deps[pkg] = version.isEmpty ? _defaultVersionConstraint : version;
        }
      }
    }

    return deps;
  }

  /// Resolves `.dart_tool/package_config.json` for the required dependencies.
  ///
  /// Priority:
  /// 1. Local project `.dart_tool/package_config.json` if present and contains all dependencies (only when no explicit package constraints are specified).
  /// 2. Ephemeral `dart pub get` execution into a temporary directory.
  static Future<String?> resolvePackageConfig(
    String code, {
    List<String>? packageConstraints,
    String? localPackageConfig,
    bool offline = false,
  }) async {
    final deps = collectDependencies(code, packages: packageConstraints);
    if (deps.isEmpty) {
      return localPackageConfig;
    }

    // 1. Check local package config
    if (localPackageConfig != null) {
      final configFile = File(localPackageConfig);
      if (!configFile.existsSync()) {
        throw StateError(
          'Specified package configuration file does not exist: "$localPackageConfig"',
        );
      }
      final PackageConfig config;
      try {
        config = await loadPackageConfig(configFile);
      } catch (e) {
        throw StateError(
          'Failed to parse package configuration file "$localPackageConfig": $e',
        );
      }
      // Only reuse local config when no explicit package constraints were passed.
      if (packageConstraints == null || packageConstraints.isEmpty) {
        final localPkgNames = {for (final p in config.packages) p.name};
        if (deps.keys.every(localPkgNames.contains)) {
          return localPackageConfig;
        }
      }
    }

    // 2. Ephemeral pub get in a temporary directory (no persistent caching)
    final tempDir = Directory.systemTemp.createTempSync('dart_eval_');

    final match = _sdkVersionRegExp.firstMatch(Platform.version);
    if (match == null) {
      throw StateError(
        'Could not parse SDK version from Platform.version: "${Platform.version}"',
      );
    }
    final sdkVersion = match.group(1)!;
    final sortedDeps = deps.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final pubspecBuffer = StringBuffer()
      ..writeln('name: $_evalWorkspaceName')
      ..writeln('environment:')
      ..writeln('  sdk: "^$sdkVersion"')
      ..writeln('dependencies:');

    for (final entry in sortedDeps) {
      final val = entry.value;
      if (val.startsWith('{') || val.startsWith('[') || val.contains('\n')) {
        pubspecBuffer.writeln('  ${entry.key}: $val');
      } else {
        pubspecBuffer.writeln('  ${entry.key}: "$val"');
      }
    }

    File(
      path.join(tempDir.path, 'pubspec.yaml'),
    ).writeAsStringSync(pubspecBuffer.toString());

    final dartBin = Platform.resolvedExecutable;
    final result = await Process.run(
      dartBin,
      [
        'pub',
        'get',
        if (offline) '--offline',
      ],
      workingDirectory: tempDir.path,
    );

    final generatedConfig = File(
      path.join(tempDir.path, '.dart_tool', 'package_config.json'),
    );

    if (result.exitCode != 0 || !generatedConfig.existsSync()) {
      final stderrOut = result.stderr.toString().trim();
      final stdoutOut = result.stdout.toString().trim();
      throw StateError(
        'Failed to resolve package dependencies for evaluation snippet:\n\n'
        'stdout:\n'
        '$stdoutOut\n\n'
        'stderr:\n'
        '$stderrOut',
      );
    }

    return generatedConfig.path;
  }
}
