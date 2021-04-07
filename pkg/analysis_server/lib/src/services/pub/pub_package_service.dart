// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/src/services/pub/pub_api.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:meta/meta.dart';

/// Information about Pub packages that can be converted to/from JSON and
/// cached to disk.
class PackageDetailsCache {
  static const cacheVersion = 2;
  static const maxCacheAge = Duration(hours: 18);
  final Map<String, PubPackage> packages;
  DateTime lastUpdatedUtc;

  PackageDetailsCache._(this.packages, DateTime lastUpdated)
      : lastUpdatedUtc = lastUpdated.toUtc();

  Duration get cacheTimeRemaining {
    final cacheAge = DateTime.now().toUtc().difference(lastUpdatedUtc);
    final cacheTimeRemaining = maxCacheAge - cacheAge;
    return cacheTimeRemaining < Duration.zero
        ? Duration.zero
        : cacheTimeRemaining;
  }

  Map<String, Object> toJson() {
    return {
      'version': cacheVersion,
      'lastUpdated': lastUpdatedUtc.toIso8601String(),
      'packages': packages.values.toList(),
    };
  }

  static PackageDetailsCache empty() {
    return PackageDetailsCache._({}, DateTime.utc(2000));
  }

  static PackageDetailsCache fromApiResults(List<PubApiPackage> apiPackages) {
    final packages = Map.fromEntries(apiPackages.map((package) =>
        MapEntry(package.packageName, PubPackage.fromName(package))));

    return PackageDetailsCache._(packages, DateTime.now().toUtc());
  }

  /// Deserializes cached package data from JSON.
  ///
  /// If the JSON version does not match the current version, will return null.
  static PackageDetailsCache? fromJson(Map<String, Object?> json) {
    if (json['version'] != cacheVersion) {
      return null;
    }

    final packagesJson = json['packages'];
    if (packagesJson is! List<Object>) {
      return null;
    }

    final packages = <PubPackage>[];
    for (final packageJson in packagesJson) {
      if (packageJson is! Map<String, Object?>) {
        return null;
      }
      final nameJson = packageJson['packageName'];
      if (nameJson is! String) {
        return null;
      }
      packages.add(PubPackage.fromJson(nameJson));
    }

    final packageMap = Map.fromEntries(
      packages.map(
        (package) => MapEntry(package.packageName, package),
      ),
    );

    final lastUpdatedJson = json['lastUpdated'];
    if (lastUpdatedJson is! String) {
      return null;
    }
    final lastUpdated = DateTime.tryParse(lastUpdatedJson);
    if (lastUpdated == null) {
      return null;
    }

    return PackageDetailsCache._(packageMap, lastUpdated);
  }
}

/// Information about a single Pub package.
class PubPackage {
  String packageName;

  PubPackage.fromJson(this.packageName);

  PubPackage.fromName(PubApiPackage package)
      : packageName = package.packageName;

  Map<String, Object> toJson() {
    return {
      'packageName': packageName,
    };
  }
}

/// A service for providing Pub package information.
///
/// Uses a [PubApi] to communicate with Pub and caches to disk using [cacheResourceProvider].
class PubPackageService {
  final InstrumentationService _instrumentationService;
  final PubApi _api;
  Timer? _nextRequestTimer;

  /// [ResourceProvider] used for caching. This should generally be a
  /// [PhysicalResourceProvider] outside of tests.
  final ResourceProvider cacheResourceProvider;

  /// The current cache of package information. Initially `null`, but
  /// overwritten after first read of cache from disk or fetch from the API.
  @visibleForTesting
  PackageDetailsCache? packageCache;

  PubPackageService(
      this._instrumentationService, this.cacheResourceProvider, this._api);

  /// Gets the last set of package results or an empty List if no results.
  List<PubPackage> get cachedPackages =>
      packageCache?.packages.values.toList() ?? [];

  bool get isRunning => _nextRequestTimer != null;

  @visibleForTesting
  File get packageCacheFile {
    final cacheFolder = cacheResourceProvider
        .getStateLocation('.pub-package-details-cache')!
      ..create();
    return cacheFolder.getChildAssumingFile('packages.json');
  }

  /// Begin a request to pre-load the package name list.
  void beginPackageNamePreload() {
    // If first time, try to read from disk.
    var packageCache = this.packageCache;
    if (packageCache == null) {
      packageCache ??= readDiskCache() ?? PackageDetailsCache.empty();
      this.packageCache = packageCache;
    }

    // If there is no queued request, initialize one when the current cache expires.
    _nextRequestTimer ??=
        Timer(packageCache.cacheTimeRemaining, _fetchFromServer);
  }

  @visibleForTesting
  PackageDetailsCache? readDiskCache() {
    final file = packageCacheFile;
    if (!file.exists) {
      return null;
    }
    try {
      final contents = file.readAsStringSync();
      final json = jsonDecode(contents);
      if (json is Map<String, Object?>) {
        return PackageDetailsCache.fromJson(json);
      }
    } catch (e) {
      _instrumentationService.logError('Error reading pub cache file: $e');
      return null;
    }
  }

  void shutdown() => _nextRequestTimer?.cancel();

  @visibleForTesting
  void writeDiskCache(PackageDetailsCache cache) {
    final file = packageCacheFile;
    file.writeAsStringSync(jsonEncode(cache.toJson()));
  }

  Future<void> _fetchFromServer() async {
    try {
      final packages = await _api.allPackages();

      // If we never got a valid response, just skip until the next refresh.
      if (packages == null) {
        return;
      }

      final packageCache = PackageDetailsCache.fromApiResults(packages);
      this.packageCache = packageCache;
      writeDiskCache(packageCache);
    } catch (e) {
      _instrumentationService.logError('Failed to fetch packages from Pub: $e');
    } finally {
      _nextRequestTimer =
          Timer(PackageDetailsCache.maxCacheAge, _fetchFromServer);
    }
  }
}
