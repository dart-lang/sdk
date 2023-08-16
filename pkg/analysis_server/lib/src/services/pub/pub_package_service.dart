// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/src/services/pub/pub_api.dart';
import 'package:analysis_server/src/services/pub/pub_command.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:meta/meta.dart';

/// Information about Pub packages that can be converted to/from JSON and
/// cached to disk.
class PackageDetailsCache {
  static const cacheVersion = 3;
  static const maxCacheAge = Duration(hours: 18);
  static const maxPackageDetailsRequestsInFlight = 5;

  /// Requests to write the cache from fetching package details will be
  /// debounced by this duration to prevent many writes while the user may be
  /// cursoring though completion requests that will trigger fetching
  /// descriptions/versions.
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
/// Uses a [PubApi] to communicate with the Pub API and a [PubCommand] to
/// interact with the local `pub` command.
///
/// Expensive results are cached to disk using [resourceProvider].
class PubPackageService {
  final InstrumentationService _instrumentationService;
  final PubApi _api;

  /// A wrapper over the "pub" command line too.
  ///
  /// This can be null when not running on a real file system because it may
  /// try to interact with folders that don't really exist.
  final PubCommand? _command;

  Timer? _nextPackageNameListRequestTimer;
  Timer? _nextWriteDiskCacheTimer;

  /// [ResourceProvider] used for accessing the disk for caches and checking
  /// project types. This will be a [PhysicalResourceProvider] outside of tests.
  final ResourceProvider resourceProvider;

  /// The current cache of package information. Initially `null`, but
  /// overwritten after first read of cache from disk or fetch from the API.
  @visibleForTesting
  PackageDetailsCache? packageCache;

  int _packageDetailsRequestsInFlight = 0;

  /// A cache of version numbers from running the "pub outdated" command used
  /// for completion in pubspec.yaml.
  final _pubspecPackageVersions =
      <String, Map<String, PubOutdatedPackageDetails>>{};

  PubPackageService(this._instrumentationService, this.resourceProvider,
      this._api, this._command);

  /// Gets the last set of package results from the Pub API or an empty List if
  /// no results.
  ///
  /// This data is used for completion of package names in pubspec.yaml
  /// and for clients that support lazy resolution of completion items may also
  /// include their descriptions and/or version numbers.
  List<PubPackage> get cachedPackages =>
      packageCache?.packages.values.toList() ?? [];

  @visibleForTesting
  bool get isPackageNamesTimerRunning =>
      _nextPackageNameListRequestTimer != null;

  @visibleForTesting
  File get packageCacheFile {
    final cacheFolder = resourceProvider
        .getStateLocation('.pub-package-details-cache')!
      ..create();
    return cacheFolder.getChildAssumingFile('packages.json');
  }

  /// Begins preloading caches for package names and pub versions.
  void beginCachePreloads(List<String> pubspecs) {
    beginPackageNamePreload();
    for (final pubspec in pubspecs) {
      fetchPackageVersionsViaPubOutdated(pubspec, pubspecWasModified: false);
    }
  }

  /// Begin a timer to pre-load and update the package name list if one has not
  /// already been started.
  void beginPackageNamePreload() {
    if (isPackageNamesTimerRunning) {
      return;
    }

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

  /// Gets the latest cached package version fetched from the Pub API for the
  /// package [packageName].
  String? cachedPubApiLatestVersion(String packageName) =>
      packageCache?.packages[packageName]?.latestVersion;

  /// Gets the package versions cached using "pub outdated" for the package
  /// [packageName] for the project using [pubspecPath].
  ///
  /// Versions in here might only be available for packages that are in the
  /// pubspec on disk. Newly-added packages in the overlay might not be
  /// available.
  PubOutdatedPackageDetails? cachedPubOutdatedVersions(
      String pubspecPath, String packageName) {
    final pubspecCache = _pubspecPackageVersions[pubspecPath];
    return pubspecCache != null ? pubspecCache[packageName] : null;
  }

  /// Begin a request to pre-load package versions using the "pub outdated"
  /// command.
  ///
  /// If [pubspecWasModified] is true, the command will always be run. Otherwise it
  /// will only be run if data is not already cached.
  Future<void> fetchPackageVersionsViaPubOutdated(String pubspecPath,
      {required bool pubspecWasModified}) async {
    final pubCommand = _command;
    if (pubCommand == null) {
      return;
    }

    // If we already have a cache for the file and it was not modified (only
    // opened) we do not need to re-run the command.
    if (!pubspecWasModified &&
        _pubspecPackageVersions.containsKey(pubspecPath)) {
      return;
    }

    // Check if this pubspec is inside a DEPS-managed folder, and if so
    // just cache an empty set of results since Pub is not managing
    // dependencies.
    if (_hasAncestorDEPSFile(pubspecPath)) {
      _pubspecPackageVersions.putIfAbsent(pubspecPath, () => {});
      return;
    }

    final results = await pubCommand.outdatedVersions(pubspecPath);
    final cache = _pubspecPackageVersions.putIfAbsent(pubspecPath, () => {});
    for (final package in results) {
      // We use the versions from the "pub outdated" results but only cache them
      // in-memory for this specific pubspec, as the resolved version may be
      // restricted by constraints/dependencies in the pubspec. The "pub"
      // command does caching of the JSON versions to make "pub outdated" fast.
      cache[package.packageName] = package;
    }
  }

  /// Clears package caches for [pubspecPath].
  ///
  /// Does not remove other caches that are not pubspec-specific (for example
  /// the latest version pulled directly from the Pub API independent of
  /// pubspec).
  Future<void> flushPackageCaches(String pubspecPath) async {
    _pubspecPackageVersions.remove(pubspecPath);
  }

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
      } else {
        return null;
      }
    } catch (e) {
      _instrumentationService.logError('Error reading pub cache file: $e');
      return null;
    }
  }

  void shutdown() {
    _nextPackageNameListRequestTimer?.cancel();
    _command?.shutdown();
  }

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

  /// Checks whether there is a DEPS file in any folder walking up from the
  /// pubspec at [pubspecPath].
  bool _hasAncestorDEPSFile(String pubspecPath) {
    var pathContext = resourceProvider.pathContext;
    var folder = pathContext.dirname(pubspecPath);
    do {
      if (resourceProvider.getFile(pathContext.join(folder, 'DEPS')).exists) {
        return true;
      }
      folder = pathContext.dirname(folder);
    } while (folder != pathContext.dirname(folder));
    return false;
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
