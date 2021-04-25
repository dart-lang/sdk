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
  static const cacheVersion = 3;
  static const maxCacheAge = Duration(hours: 18);
  static const maxPackageDetailsRequestsInFlight = 5;

  /// Requests to write the cache from fetching packge details will be debounced
  /// by this duration to prevent many writes while the user may be cursoring
  /// though completion requests that will trigger fetching descriptions/versions.
  static const _writeCacheDebounceDuration = Duration(seconds: 3);

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
    if (packagesJson is! List<Object?>) {
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
      packages.add(PubPackage.fromJson(packageJson));
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
  String? description;
  String? latestVersion;

  PubPackage.fromDetails(PubApiPackageDetails package)
      : packageName = package.packageName,
        description = package.description,
        latestVersion = package.latestVersion;

  PubPackage.fromJson(Map<String, Object?> json)
      : packageName = json['packageName'] as String,
        description = json['description'] as String?,
        latestVersion = json['latestVersion'] as String?;

  PubPackage.fromName(PubApiPackage package)
      : packageName = package.packageName;

  Map<String, Object> toJson() {
    return {
      'packageName': packageName,
      if (description != null) 'description': description!,
      if (latestVersion != null) 'latestVersion': latestVersion!,
    };
  }
}

/// A service for providing Pub package information.
///
/// Uses a [PubApi] to communicate with Pub and caches to disk using [cacheResourceProvider].
class PubPackageService {
  final InstrumentationService _instrumentationService;
  final PubApi _api;
  Timer? _nextPackageNameListRequestTimer;
  Timer? _nextWriteDiskCacheTimer;

  /// [ResourceProvider] used for caching. This should generally be a
  /// [PhysicalResourceProvider] outside of tests.
  final ResourceProvider cacheResourceProvider;

  /// The current cache of package information. Initially `null`, but
  /// overwritten after first read of cache from disk or fetch from the API.
  @visibleForTesting
  PackageDetailsCache? packageCache;

  int _packageDetailsRequestsInFlight = 0;

  PubPackageService(
      this._instrumentationService, this.cacheResourceProvider, this._api);

  /// Gets the last set of package results or an empty List if no results.
  List<PubPackage> get cachedPackages =>
      packageCache?.packages.values.toList() ?? [];

  bool get isRunning => _nextPackageNameListRequestTimer != null;

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
    var cache = packageCache;
    if (cache == null) {
      cache ??= readDiskCache() ?? PackageDetailsCache.empty();
      packageCache = cache;
    }

    // If there is no queued request, initialize one when the current cache expires.
    _nextPackageNameListRequestTimer ??=
        Timer(cache.cacheTimeRemaining, _fetchFromServer);
  }

  /// Gets the cached package details for package [packageName].
  ///
  /// Returns null if no package details are cached.
  PubPackage? cachedPackageDetails(String packageName) =>
      packageCache?.packages[packageName];

  /// Gets package details for package [packageName].
  ///
  /// If the package details are not cached, will call the Pub API and cache
  /// the result. Results are cached for the same period as the main package
  /// list cache - that is, when the package list cache expires, all cached
  /// package details will go with it.
  Future<PubPackage?> packageDetails(String packageName) async {
    var packageData = packageCache?.packages[packageName];
    // If we don't have the version for this package, we don't have its full details.
    if (packageData?.latestVersion == null &&
        // Limit the number of package details requests that can be in-flight at
        // once since an editor may send many of these requests as the user
        // cursors through the results (a good editor will cancel the resolve
        // requests, but we may have already started the requests synchronously
        // before handling a cancellation).
        _packageDetailsRequestsInFlight <=
            PackageDetailsCache.maxPackageDetailsRequestsInFlight) {
      _packageDetailsRequestsInFlight++;
      try {
        final details = await _api.packageInfo(packageName);
        if (details != null) {
          packageData = PubPackage.fromDetails(details);
          packageCache?.packages[packageName] = packageData;
          _writeDiskCacheDebounced();
        }
      } finally {
        _packageDetailsRequestsInFlight--;
      }
    }
    return packageData;
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

  void shutdown() => _nextPackageNameListRequestTimer?.cancel();

  @visibleForTesting
  void writeDiskCache([PackageDetailsCache? cache]) {
    cache ??= packageCache;
    if (cache == null) {
      return;
    }
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
      writeDiskCache();
    } catch (e) {
      _instrumentationService.logError('Failed to fetch packages from Pub: $e');
    } finally {
      _nextPackageNameListRequestTimer =
          Timer(PackageDetailsCache.maxCacheAge, _fetchFromServer);
    }
  }

  /// Writes the package cache to disk after
  /// [PackageDetailsCache._writeCacheDebounceDuration] has elapsed, restarting
  /// the timer each time this method is called.
  void _writeDiskCacheDebounced() {
    _nextWriteDiskCacheTimer?.cancel();
    _nextWriteDiskCacheTimer =
        Timer(PackageDetailsCache._writeCacheDebounceDuration, writeDiskCache);
  }
}
