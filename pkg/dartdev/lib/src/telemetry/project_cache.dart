// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart_data_home/dart_data_home.dart';
import 'package:path/path.dart' as path;

import 'pubspec_scanner.dart';

/// Manage local disk caching of evaluated project telemetry in
/// `~/.dart/dartdev/project_telemetry_cache.json`.
///
/// Implements:
/// - FNV-1a path hashing for developer anonymity.
/// - Storage of pubspec content hash and last sent timestamp.
/// - 100-project LRU eviction cap.
/// - Silent failure guarantee via complete `try-catch` isolation.
class ProjectTelemetryCache {
  static const int _maxProjects = 100;
  static const int supportedVersion = 1;

  final File cacheFile;

  ProjectTelemetryCache([File? file])
    : cacheFile =
          file ??
          File(
            path.join(
              getDartDataHome('dartdev'),
              'project_telemetry_cache.json',
            ),
          );

  /// Retrieves the raw cache entry for [projectPath]. Returns `null` on cache miss
  /// or any filesystem/parsing error.
  ProjectCacheEntry? getEntry(String projectPath) {
    try {
      if (!cacheFile.existsSync()) {
        return null;
      }

      final doc = ProjectCacheDocument.fromJson(
        jsonDecode(cacheFile.readAsStringSync()),
      );
      if (doc == null) return null;

      final key = hash(projectPath);
      final entry = doc.projects[key];
      if (entry == null) return null;

      return entry;
    } catch (_) {
      return null; // Fail silently
    }
  }

  /// Writes or updates the cache entry for [projectPath] with [telemetry],
  /// updating `last_sent_seconds` to now and evicting the oldest entries if the
  /// total exceeds 100 projects.
  void set(
    String projectPath,
    PubspecTelemetry telemetry, {
    required String contentHash,
    int? nowSeconds,
  }) {
    try {
      var doc = ProjectCacheDocument();

      if (cacheFile.existsSync()) {
        try {
          doc =
              ProjectCacheDocument.fromJson(
                jsonDecode(cacheFile.readAsStringSync()),
              ) ??
              ProjectCacheDocument();
        } catch (_) {
          // If existing cache file is corrupted, start fresh
        }
      }

      final key = hash(projectPath);
      final now = nowSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      doc.projects[key] = ProjectCacheEntry.fromTelemetry(
        telemetry,
        sentAtSeconds: now,
        contentHash: contentHash,
      );

      // LRU Eviction: if exceeding 100 projects, remove oldest by last_sent_seconds
      if (doc.projects.length > _maxProjects) {
        final entries = doc.projects.entries.toList()
          ..sort(
            (a, b) =>
                a.value.lastSentSeconds.compareTo(b.value.lastSentSeconds),
          );

        while (entries.length > _maxProjects) {
          final oldest = entries.removeAt(0);
          doc.projects.remove(oldest.key);
        }
      }

      final output = jsonEncode(doc.toJson());

      if (!cacheFile.parent.existsSync()) {
        cacheFile.parent.createSync(recursive: true);
      }
      cacheFile.writeAsStringSync(output);
    } catch (_) {
      // Fail silently to guarantee CLI stability
    }
  }

  /// Computes a 64-bit FNV-1a hash of [input] and returns it as a 16-char hex string.
  static String hash(String input) {
    var hash = 0xcbf29ce484222325;
    for (var i = 0; i < input.length; i++) {
      hash = (hash ^ input.codeUnitAt(i)) * 0x100000001b3;
    }
    return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }
}

/// A strongly-typed model representing an individual project entry in the
/// telemetry disk cache.
final class ProjectCacheEntry {
  final int lastSentSeconds;
  final String contentHash;
  final Set<String> publicDependencies;
  final bool hasFlutterSdk;
  final String? environmentSdk;

  const ProjectCacheEntry({
    required this.lastSentSeconds,
    required this.contentHash,
    required this.publicDependencies,
    required this.hasFlutterSdk,
    this.environmentSdk,
  });

  factory ProjectCacheEntry.fromTelemetry(
    PubspecTelemetry telemetry, {
    required int sentAtSeconds,
    required String contentHash,
  }) => ProjectCacheEntry(
    lastSentSeconds: sentAtSeconds,
    contentHash: contentHash,
    publicDependencies: telemetry.publicDependencies,
    hasFlutterSdk: telemetry.hasFlutterSdk,
    environmentSdk: telemetry.environmentSdk,
  );

  Map<String, Object?> toJson() => {
    'last_sent_seconds': lastSentSeconds,
    'content_hash': contentHash,
    'public_dependencies': publicDependencies.toList()..sort(),
    'has_flutter_sdk': hasFlutterSdk,
    'environment_sdk': environmentSdk,
  };

  static ProjectCacheEntry? fromJson(Object? json) => switch (json) {
    {
      'last_sent_seconds': int lastSentSeconds,
      'content_hash': String contentHash,
      'public_dependencies': List<dynamic> publicDeps,
      'has_flutter_sdk': bool hasFlutterSdk,
      'environment_sdk': String? environmentSdk,
    } =>
      ProjectCacheEntry(
        lastSentSeconds: lastSentSeconds,
        contentHash: contentHash,
        publicDependencies: publicDeps.whereType<String>().toSet(),
        hasFlutterSdk: hasFlutterSdk,
        environmentSdk: environmentSdk,
      ),
    _ => null,
  };
}

/// A strongly-typed model representing the top-level document structure of the
/// telemetry disk cache file.
final class ProjectCacheDocument {
  final int version;
  final Map<String, ProjectCacheEntry> projects;

  ProjectCacheDocument({
    this.version = ProjectTelemetryCache.supportedVersion,
    Map<String, ProjectCacheEntry>? projects,
  }) : projects = projects ?? <String, ProjectCacheEntry>{};

  Map<String, Object?> toJson() => {
    'version': version,
    'projects': projects.map((k, v) => MapEntry(k, v.toJson())),
  };

  static ProjectCacheDocument? fromJson(Object? json) {
    if (json case {
      'version': int version,
      'projects': Map<String, dynamic> rawProjects,
    }) {
      if (version != ProjectTelemetryCache.supportedVersion) return null;
      final parsed = <String, ProjectCacheEntry>{};
      for (final MapEntry(:key, :value) in rawProjects.entries) {
        if (ProjectCacheEntry.fromJson(value) case final entry?) {
          parsed[key] = entry;
        }
      }
      return ProjectCacheDocument(version: version, projects: parsed);
    }
    return null;
  }
}
