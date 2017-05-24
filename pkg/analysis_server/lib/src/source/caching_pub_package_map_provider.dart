// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:core';
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The function used to write the cache file.
 * Returns the modification stamp for the newly written file.
 */
typedef int WriteFile(File file, String content);

/**
 * [PubPackageMapProvider] extension which caches pub list results.
 * These results are cached in memory and in a single place on disk that is
 * shared cross session and between different simultaneous sessions.
 *
 * TODO(paulberry): before this class is used again, it should be ported over
 * to extend OptimizingPubPackageMapProvider instead of PubPackageMapProvider.
 */
class CachingPubPackageMapProvider extends PubPackageMapProvider {
  static const cacheKey = 'pub_list_cache';
  static const cacheVersion = 1;
  static const cacheVersionKey = 'pub_list_cache_version';
  static const pubListResultKey = 'pub_list_result';
  static const modificationStampsKey = 'modification_stamps';

  /**
   * A cache of folder path to pub list information as shown below
   * or `null` if the cache has not yet been initialized.
   *
   *     {
   *       "path/to/folder": {
   *         "pub_list_result": {
   *           "packages": {
   *             "foo": "path/to/foo",
   *             "bar": ["path/to/bar1", "path/to/bar2"],
   *             "myapp": "path/to/myapp",  // self link is included
   *           },
   *           "input_files": [
   *             "path/to/myapp/pubspec.lock"
   *           ]
   *         },
   *         "modification_stamps": {
   *           "path/to/myapp/pubspec.lock": 1424305309
   *         }
   *       }
   *       "path/to/another/folder": {
   *         ...
   *       }
   *       ...
   *     }
   */
  Map<String, Map> _cache;

  /**
   * The modification time of the cache file
   * or `null` if it has not yet been read.
   */
  int _cacheModificationTime;

  /**
   * The function used to write the cache file.
   */
  WriteFile _writeFile;

  /**
   * Construct a new instance.
   * [RunPubList] and [WriteFile] implementations may be injected for testing
   */
  CachingPubPackageMapProvider(
      ResourceProvider resourceProvider, FolderBasedDartSdk sdk,
      [RunPubList runPubList, this._writeFile])
      : super(resourceProvider, sdk, runPubList) {
    if (_writeFile == null) {
      _writeFile = _writeFileDefault;
    }
  }

  File get cacheFile => _cacheDir.getChild('cache');
  Folder get _cacheDir => resourceProvider.getStateLocation('.pub-list');
  File get _touchFile => _cacheDir.getChild('touch');

  @override
  PackageMapInfo computePackageMap(Folder folder) {
    //
    // Return error if folder does not exist, but don't remove previously
    // cached result because folder may be only temporarily inaccessible
    //
    if (!folder.exists) {
      return computePackageMapError(folder);
    }
    // Ensure cache is up to date
    _readCache();
    // Check for cached entry
    Map entry = _cache[folder.path];
    if (entry != null) {
      Map<String, int> modificationStamps =
          entry[modificationStampsKey] as Map<String, int>;
      if (modificationStamps != null) {
        //
        // Check to see if any dependencies have changed
        // before returning cached result
        //
        if (!_haveDependenciesChanged(modificationStamps)) {
          return parsePackageMap(entry[pubListResultKey], folder);
        }
      }
    }
    int runCount = 0;
    PackageMapInfo info;
    while (true) {
      // Capture the current time so that we can tell if an input file
      // has changed while running pub list. This is done
      // by writing to a file rather than getting millisecondsSinceEpoch
      // because file modification time has different granularity
      // on different systems.
      int startStamp;
      try {
        startStamp = _writeFile(_touchFile, 'touch');
      } catch (exception, stackTrace) {
        AnalysisEngine.instance.logger.logInformation(
            'Exception writing $_touchFile\n$exception\n$stackTrace');
        startStamp = new DateTime.now().millisecondsSinceEpoch;
      }
      // computePackageMap calls parsePackageMap which caches the result
      info = super.computePackageMap(folder);
      ++runCount;
      if (!_haveDependenciesChangedSince(info, startStamp)) {
        // If no dependencies have changed while running pub then finished
        break;
      }
      if (runCount == 4) {
        // Don't run forever
        AnalysisEngine.instance.logger
            .logInformation('pub list called $runCount times: $folder');
        break;
      }
    }
    _writeCache();
    return info;
  }

  @override
  PackageMapInfo parsePackageMap(Map obj, Folder folder) {
    PackageMapInfo info = super.parsePackageMap(obj, folder);
    Map<String, int> modificationStamps = new Map<String, int>();
    for (String path in info.dependencies) {
      Resource res = resourceProvider.getResource(path);
      if (res is File && res.exists) {
        modificationStamps[path] = res.createSource().modificationStamp;
      }
    }
    // Assumes entry has been initialized by computePackageMap
    _cache[folder.path] = <String, Map>{
      pubListResultKey: obj,
      modificationStampsKey: modificationStamps
    };
    return info;
  }

  /**
   * Determine if any of the dependencies have changed.
   */
  bool _haveDependenciesChanged(Map<String, int> modificationStamps) {
    for (String path in modificationStamps.keys) {
      Resource res = resourceProvider.getResource(path);
      if (res is File) {
        if (!res.exists ||
            res.createSource().modificationStamp != modificationStamps[path]) {
          return true;
        }
      } else {
        return true;
      }
    }
    return false;
  }

  /**
   * Determine if any of the dependencies have changed since the given time.
   */
  bool _haveDependenciesChangedSince(PackageMapInfo info, int startStamp) {
    for (String path in info.dependencies) {
      Resource res = resourceProvider.getResource(path);
      if (res is File) {
        int modStamp = res.createSource().modificationStamp;
        if (modStamp != null && modStamp >= startStamp) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Read the cache from disk if it has not been read before.
   */
  void _readCache() {
    // TODO(danrubel) This implementation assumes that
    // two separate processes are not accessing the cache file at the same time
    Source source = cacheFile.createSource();
    if (source.exists() &&
        (_cache == null ||
            _cacheModificationTime != source.modificationStamp)) {
      try {
        TimestampedData<String> data = source.contents;
        Map map = JSON.decode(data.data);
        if (map[cacheVersionKey] == cacheVersion) {
          _cache = map[cacheKey] as Map<String, Map>;
          _cacheModificationTime = data.modificationTime;
        }
      } catch (exception, stackTrace) {
        AnalysisEngine.instance.logger.logInformation(
            'Exception reading $cacheFile\n$exception\n$stackTrace');
      }
    }
    if (_cache == null) {
      _cache = new Map<String, Map>();
    }
  }

  /**
   * Write the cache to disk.
   */
  void _writeCache() {
    try {
      _cacheModificationTime = _writeFile(cacheFile,
          JSON.encode({cacheVersionKey: cacheVersion, cacheKey: _cache}));
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logInformation(
          'Exception writing $cacheFile\n$exception\n$stackTrace');
    }
  }

  /**
   * Update the given file with the specified content.
   */
  int _writeFileDefault(File cacheFile, String content) {
    // TODO(danrubel) This implementation assumes that
    // two separate processes are not accessing the cache file at the same time
    io.File file = new io.File(cacheFile.path);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync(content, flush: true);
    return file.lastModifiedSync().millisecondsSinceEpoch;
  }
}
