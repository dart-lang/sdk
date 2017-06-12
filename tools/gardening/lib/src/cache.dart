// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'util.dart';

final Cache cache = new Cache(Uri.base.resolve('temp/gardening-cache/'));

/// Simple cache for test step output.
class Cache {
  Uri base;

  Cache(this.base);

  Map<String, String> memoryCache = <String, String>{};

  /// Load the cache text for [path] or call [ifAbsent] to fetch the data.
  Future<String> read(String path, Future<String> ifAbsent()) async {
    if (memoryCache.containsKey(path)) {
      log('Found $path in memory cache');
      return memoryCache[path];
    }
    File file = new File.fromUri(base.resolve(path));
    String text;
    if (file.existsSync()) {
      log('Found $path in file cache');
      text = file.readAsStringSync();
      memoryCache[path] = text;
    } else {
      log('Loading $path');
      text = await ifAbsent();
      write(path, text);
    }
    return text;
  }

  /// Store [text] as the cache data for [path].
  void write(String path, String text) {
    log('Creating $path in file cache');
    File file = new File.fromUri(base.resolve(path));
    file.createSync(recursive: true);
    file.writeAsStringSync(text);
    memoryCache[path] = text;
  }
}
