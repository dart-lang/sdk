// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

typedef PubspecTelemetry = ({
  Set<String> publicDependencies,
  bool hasFlutterSdk,
  String? environmentSdk,
});

/// Locates `pubspec.yaml` in [dir] or an ancestor directory.
File? findPubspecFile(Directory dir) => _findFile(dir, 'pubspec.yaml');

/// Statelessly scans for a `pubspec.yaml` in [dir] or its parent hierarchy
/// and extracts direct public dependencies, applying strict privacy
/// verification against `.dart_tool/package_config.json`.
///
/// Note: This will not collect information in a Bazel workspace because Bazel
/// does not generate a `.dart_tool/package_config.json` file.
///
/// Returns `null` if no pubspec is found, if `.dart_tool/package_config.json`
/// is missing, or if any file system or parsing error occurs.
PubspecTelemetry? scanPubspecTelemetry(
  Directory dir, {
  Map<String, String>? environment,
}) {
  try {
    final pubspecFile = findPubspecFile(dir);
    if (pubspecFile == null) return null;

    // In Dart 3.5+ Pub Workspaces, package_config.json may be in the current
    // package or in an ancestor workspace root.
    final packageConfigFile = _findFile(
      pubspecFile.parent,
      path.join('.dart_tool', 'package_config.json'),
    );
    if (packageConfigFile == null) return null;

    final hostedPublicPackages = _extractHostedPublicPackages(
      packageConfigFile,
      environment ?? Platform.environment,
    );
    if (hostedPublicPackages == null) return null;

    final doc = loadYaml(pubspecFile.readAsStringSync());
    if (doc is! YamlMap) return null;

    final publicDeps = <String>{};
    bool hasFlutterSdk = false;
    String? environmentSdk;

    // Check environment for flutter sdk and sdk constraint
    if (doc['environment'] case YamlMap environment) {
      if (environment.containsKey('flutter')) {
        hasFlutterSdk = true;
      }
      if (environment['sdk'] case final Object sdk) {
        final rawSdk = sdk.toString().trim();
        if (rawSdk.isNotEmpty) {
          environmentSdk = rawSdk.length > 100
              ? rawSdk.substring(0, 100)
              : rawSdk;
        }
      }
    }

    void processDependencies(Object? deps) {
      if (deps case YamlMap map) {
        for (final MapEntry(:key, :value) in map.entries) {
          if (key is! String) continue;

          if (key == 'flutter') {
            if (value case {'sdk': 'flutter'}) {
              hasFlutterSdk = true;
              continue;
            }
          }

          if (_isCandidatePublicDependency(value) &&
              hostedPublicPackages.contains(key)) {
            publicDeps.add(key);
          }
        }
      }
    }

    processDependencies(doc['dependencies']);
    processDependencies(doc['dev_dependencies']);

    return (
      publicDependencies: publicDeps,
      hasFlutterSdk: hasFlutterSdk,
      environmentSdk: environmentSdk,
    );
  } catch (_) {
    return null;
  }
}

File? _findFile(Directory dir, String relativePath) {
  var current = dir;
  while (true) {
    final file = File(path.join(current.path, relativePath));
    if (file.existsSync()) return file;
    final parent = current.parent;
    if (parent.path == current.path) {
      return null; // Root reached
    }
    current = parent;
  }
}

Set<String>? _extractHostedPublicPackages(
  File packageConfigFile,
  Map<String, String> environment,
) {
  try {
    final content = packageConfigFile.readAsStringSync();
    final config = PackageConfig.parseString(content, packageConfigFile.uri);
    final hosted = <String>{};
    for (final package in config.packages) {
      if (_isPublicHostedUri(package.root, environment)) {
        hosted.add(package.name);
      }
    }
    return hosted;
  } catch (_) {
    return null;
  }
}

bool _isPublicHostedUri(Uri resolvedUri, Map<String, String> environment) {
  final segments = resolvedUri.pathSegments;
  final hostedIndex = segments.indexOf('hosted');
  if (hostedIndex <= 0 || hostedIndex + 1 >= segments.length) {
    return false;
  }

  final host = segments[hostedIndex + 1];
  if (host != 'pub.dev' && host != 'pub.dartlang.org') {
    return false;
  }

  // 1. Check if PUB_CACHE environment variable is set and matches.
  if (environment['PUB_CACHE'] case final String envCache
      when envCache.isNotEmpty) {
    final cacheUri = Directory(envCache).absolute.uri;
    if (resolvedUri.toString().startsWith(cacheUri.toString())) {
      return true;
    }
  }

  // 2. Check standard default pub cache directory names:
  // - POSIX default: ~/.pub-cache/hosted/pub.dev/...
  // - Windows default: %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\...
  final parent = segments[hostedIndex - 1];
  return parent == '.pub-cache' || parent == 'Cache' || parent == 'pub-cache';
}

bool _isCandidatePublicDependency(Object? value) => switch (value) {
  String() || null => true,
  {'hosted': String url} ||
  {'hosted': {'url': String url}} => _isPublicHostedUrl(url),
  {'version': _} => value is YamlMap && value.length == 1,
  YamlMap map => map.isEmpty,
  _ => false,
};

bool _isPublicHostedUrl(String url) => switch (Uri.tryParse(url)?.host) {
  'pub.dev' || 'pub.dartlang.org' => true,
  _ => false,
};
