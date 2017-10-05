// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'logger.dart';
import 'util.dart';

typedef Future<String> FetchDataFunction();
typedef Future<String> WithCacheFunction(FetchDataFunction fetchData,
    [String key]);
typedef WithCacheFunction CreateCacheFunction(
    {String overrideKey, Duration duration});

CreateCacheFunction initCache(Uri baseUri, [Logger logger]) {
  final cache = new Cache(baseUri, logger);
  logger ??= new StdOutLogger(Level.warning);

  return ({String overrideKey, Duration duration}) {
    if (duration == null) {
      duration = new Duration(hours: 24);
    }

    return (FetchDataFunction call, [String key]) async {
      if (overrideKey != null) {
        key = overrideKey;
      }
      if (key == null || key.isEmpty) {
        logger.warning("Key is null or empty - cannot cache result");
      } else {
        // format key
        key = key.replaceAll("/", "_").replaceAll(".", "_");
        var cacheResult = await cache.read(key, duration);
        if (cacheResult.hasResult) {
          logger.debug("Found key $key in cache");
          return cacheResult.result;
        }
      }

      logger.debug("Could not find key $key in cache");

      // we have to make a call
      String result = await call();

      // insert/update the cache
      if (key != null && !key.isEmpty) {
        await cache.write(key, result);
      }

      return result;
    };
  };
}

CreateCacheFunction noCache() {
  return ({String overrideKey, Duration duration}) {
    return (FetchDataFunction fetchData, [String key]) {
      return fetchData();
    };
  };
}

/// Simple cache for caching data.
class Cache {
  // TODO(mkroghj) use this instead of cache.dart
  Uri base;
  Logger logger;

  Cache(this.base, this.logger);

  Map<String, String> memoryCache = <String, String>{};

  /// Checks if key [path] is in cache
  Future<bool> containsKey(String path, [Duration duration]) async {
    if (memoryCache.containsKey(path)) return true;

    File file = new File.fromUri(base.resolve(path));
    if (await file.exists()) {
      return duration == null
          ? true
          : new DateTime.now().difference(await file.lastModified()) <=
              duration;
    }

    return false;
  }

  /// Try reading [path] from cache
  Future<CacheResult> read(String path, [Duration duration]) async {
    if (memoryCache.containsKey(path)) {
      logger.debug('Found $path in memory cache');
      return new CacheResult(memoryCache[path]);
    }

    File file = new File.fromUri(base.resolve(path));

    if (!await file.exists()) {
      logger.debug('Could not find file $path in file cache');
      return new CacheResult.noResult();
    }
    if (duration != null &&
        new DateTime.now().difference(await file.lastModified()) > duration) {
      logger.debug('File $path was found but the information is too stale,'
          'for the duration: $duration');
      return new CacheResult.noResult();
    }

    logger.debug('Found $path in file cache');

    try {
      String text = await file.readAsString();
      memoryCache[path] = text;
      return new CacheResult(text);
    } catch (error, st) {
      logger.error("Could not read $path:", error, st);
      return new CacheResult.noResult();
    }
  }

  /// Store [text] as the cache data for [path].
  Future write(String path, String text) async {
    logger.debug('Creating $path in file cache');
    File file = new File.fromUri(base.resolve(path));
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(text);
    memoryCache[path] = text;
  }

  /// Clears the cache at [baseUri]
  Future clearCache(Uri baseUri) async {
    await new Directory(baseUri.toFilePath()).delete(recursive: true);
  }
}

class CacheResult {
  final bool hasResult;
  final String result;

  CacheResult.noResult()
      : hasResult = false,
        result = null {}

  CacheResult(this.result) : hasResult = true {}
}
