// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:front_end/src/byte_store/byte_store.dart';
import 'package:front_end/src/byte_store/cache.dart';
import 'package:front_end/src/byte_store/file_byte_store.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

/// The function that returns current time in milliseconds.
typedef int GetCurrentTime();

/// [ByteStore] that stores values as files, allows to mark some of keys as
/// temporary protected, and supports periodical [flush] of unprotected keys.
///
/// The set of protected keys is stored in a file, which is locked during
/// updating to prevent races across multiple processes.
class ProtectedFileByteStore implements ByteStore {
  @visibleForTesting
  static const PROTECTED_FILE_NAME = '.temporary_protected_keys';

  final String _cachePath;
  final Duration _protectionDuration;
  final GetCurrentTime _getCurrentTimeFunction;

  final FileByteStore _fileByteStore;
  final Cache<String, List<int>> _cache;

  /// Create a new instance of the [ProtectedFileByteStore].
  ///
  /// The [protectionDuration] specifies how long temporary protected keys
  /// stay protected.
  ProtectedFileByteStore(this._cachePath,
      {Duration protectionDuration,
      GetCurrentTime getCurrentTime,
      int cacheSizeBytes: 128 * 1024 * 1024})
      : _protectionDuration = protectionDuration,
        _getCurrentTimeFunction = getCurrentTime ?? _getCurrentTimeDefault,
        _fileByteStore = new FileByteStore(_cachePath),
        _cache = new Cache(cacheSizeBytes, (bytes) => bytes.length);

  /// Remove all not protected keys.
  void flush() {
    var protectedKeysText = _keysReadTextLocked();
    var protectedKeys = new ProtectedKeys.decode(protectedKeysText);
    List<FileSystemEntity> files = new Directory(_cachePath).listSync();
    for (var file in files) {
      if (file is File) {
        String key = basename(file.path);
        if (key == PROTECTED_FILE_NAME) {
          continue;
        }
        if (protectedKeys.containsKey(key)) {
          continue;
        }
        try {
          file.deleteSync();
        } catch (e) {}
      }
    }
  }

  @override
  List<int> get(String key) {
    return _cache.get(key, () => _fileByteStore.get(key));
  }

  @override
  void put(String key, List<int> bytes) {
    if (key == PROTECTED_FILE_NAME) {
      throw new ArgumentError('The key $key is reserved.');
    }
    _fileByteStore.put(key, bytes);
    _cache.put(key, bytes);
  }

  /// The [add] keys are added to the set of temporary protected keys, and
  /// their age is reset to zero.
  ///
  /// The [remove] keys are removed from the set of temporary protected keys,
  /// and become subjects of LRU cached eviction.
  void updateProtectedKeys(
      {List<String> add: const <String>[],
      List<String> remove: const <String>[]}) {
    _withProtectedKeysLockSync(_cachePath, (ProtectedKeys protectedKeys) {
      var now = _getCurrentTimeFunction();

      if (_protectionDuration != null) {
        var maxAge = _protectionDuration.inMilliseconds;
        protectedKeys.removeOlderThan(maxAge, now);
      }

      for (var addedKey in add) {
        protectedKeys.add(addedKey, now);
      }

      for (var removedKey in remove) {
        protectedKeys.remove(removedKey);
      }
    });
  }

  /// Read the protected keys, but don't keep the lock.
  ///
  /// We do this before performing any long running operation that
  /// just read, and where it is important to keep system unlocked.
  String _keysReadTextLocked() {
    File keysFile = new File(join(_cachePath, PROTECTED_FILE_NAME));
    RandomAccessFile keysLock = keysFile.openSync(mode: FileMode.APPEND);
    keysLock.lockSync(FileLock.BLOCKING_EXCLUSIVE);
    try {
      return _keysReadText(keysLock);
    } finally {
      keysLock.unlockSync();
      keysLock.closeSync();
    }
  }

  /// The default implementation of [GetCurrentTime].
  static int _getCurrentTimeDefault() {
    return new DateTime.now().millisecondsSinceEpoch;
  }

  static ProtectedKeys _keysRead(RandomAccessFile file) {
    String text = _keysReadText(file);
    return new ProtectedKeys.decode(text);
  }

  static String _keysReadText(RandomAccessFile file) {
    file.setPositionSync(0);
    List<int> bytes = file.readSync(file.lengthSync());
    return utf8.decode(bytes);
  }

  static void _keysWrite(RandomAccessFile file, ProtectedKeys keys) {
    String text = keys.encode();
    file.setPositionSync(0);
    file.writeStringSync(text);
    file.truncateSync(file.positionSync());
  }

  /// Perform [f] over the locked keys file, decoded into [ProtectedKeys].
  static void _withProtectedKeysLockSync(
      String cachePath, void f(ProtectedKeys keys)) {
    String path = join(cachePath, PROTECTED_FILE_NAME);
    RandomAccessFile file = new File(path).openSync(mode: FileMode.APPEND);
    file.lockSync(FileLock.BLOCKING_EXCLUSIVE);
    try {
      ProtectedKeys keys = _keysRead(file);
      f(keys);
      _keysWrite(file, keys);
    } finally {
      file.unlockSync();
      file.closeSync();
    }
  }
}

/// Container with protected keys.
@visibleForTesting
class ProtectedKeys {
  /// The map from a key in [ByteStore] to the time in milliseconds when the
  /// key was marked as temporary protected.
  final Map<String, int> map;

  ProtectedKeys(this.map);

  factory ProtectedKeys.decode(String text) {
    var map = <String, int>{};
    try {
      List<String> lines = text.split('\n').toList();
      if (lines.length % 2 == 0) {
        for (int i = 0; i < lines.length; i += 2) {
          String key = lines[i];
          String startMillisecondsStr = lines[i + 1];
          int startMilliseconds = int.parse(startMillisecondsStr);
          map[key] = startMilliseconds;
        }
      }
    } catch (e) {}
    return new ProtectedKeys(map);
  }

  /// Add the given [key] with the current time.
  void add(String key, int time) {
    map[key] = time;
  }

  bool containsKey(String key) => map.containsKey(key);

  String encode() {
    var buffer = new StringBuffer();
    map.forEach((key, start) {
      buffer.writeln(key);
      buffer.writeln(start);
    });
    return buffer.toString().trim();
  }

  void remove(String key) {
    map.remove(key);
  }

  /// If the time is [now] milliseconds, remove all keys that are older than
  /// the given [maxAge] is milliseconds.
  void removeOlderThan(int maxAge, int now) {
    var keysToRemove = <String>[];
    for (var key in map.keys) {
      if (now - map[key] > maxAge) {
        keysToRemove.add(key);
      }
    }
    keysToRemove.forEach(map.remove);
  }
}
