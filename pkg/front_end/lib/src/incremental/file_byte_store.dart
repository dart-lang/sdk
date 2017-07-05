// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:front_end/src/incremental/byte_store.dart';
import 'package:path/path.dart';

/**
 * The request that is sent from the main isolate to the clean-up isolate.
 */
class CacheCleanUpRequest {
  final String cachePath;
  final int maxSizeBytes;
  final SendPort replyTo;

  CacheCleanUpRequest(this.cachePath, this.maxSizeBytes, this.replyTo);
}

/**
 * [ByteStore] that stores values as files and performs cache eviction.
 *
 * Only the process that manages the cache, e.g. Analysis Server, should use
 * this class. Other processes, e.g. Analysis Server plugins, should use
 * [FileByteStore] instead and let the main process to perform eviction.
 */
class EvictingFileByteStore implements ByteStore {
  static bool _cleanUpSendPortShouldBePrepared = true;
  static SendPort _cleanUpSendPort;

  final String _cachePath;
  final int _maxSizeBytes;
  final FileByteStore _fileByteStore;

  int _bytesWrittenSinceCleanup = 0;
  bool _evictionIsolateIsRunning = false;

  EvictingFileByteStore(this._cachePath, this._maxSizeBytes)
      : _fileByteStore = new FileByteStore(_cachePath) {
    _requestCacheCleanUp();
  }

  @override
  List<int> get(String key) {
    return _fileByteStore.get(key);
  }

  @override
  void put(String key, List<int> bytes) {
    _fileByteStore.put(key, bytes);
    // Update the current size.
    _bytesWrittenSinceCleanup += bytes.length;
    if (_bytesWrittenSinceCleanup > _maxSizeBytes ~/ 8) {
      _requestCacheCleanUp();
    }
  }

  /**
   * If the cache clean up process has not been requested yet, request it.
   */
  Future<Null> _requestCacheCleanUp() async {
    if (_cleanUpSendPortShouldBePrepared) {
      _cleanUpSendPortShouldBePrepared = false;
      ReceivePort response = new ReceivePort();
      await Isolate.spawn(_cacheCleanUpFunction, response.sendPort);
      _cleanUpSendPort = await response.first as SendPort;
    } else {
      while (_cleanUpSendPort == null) {
        await new Future.delayed(new Duration(milliseconds: 100), () {});
      }
    }

    if (!_evictionIsolateIsRunning) {
      _evictionIsolateIsRunning = true;
      try {
        ReceivePort response = new ReceivePort();
        _cleanUpSendPort.send(new CacheCleanUpRequest(
            _cachePath, _maxSizeBytes, response.sendPort));
        await response.first;
      } finally {
        _evictionIsolateIsRunning = false;
        _bytesWrittenSinceCleanup = 0;
      }
    }
  }

  /**
   * This function is started in a new isolate, receives cache folder clean up
   * requests and evicts older files from the folder.
   */
  static void _cacheCleanUpFunction(SendPort initialReplyTo) {
    ReceivePort port = new ReceivePort();
    initialReplyTo.send(port.sendPort);
    port.listen((request) async {
      if (request is CacheCleanUpRequest) {
        await _cleanUpFolder(request.cachePath, request.maxSizeBytes);
        // Let the client know that we're done.
        request.replyTo.send(true);
      }
    });
  }

  static Future<Null> _cleanUpFolder(String cachePath, int maxSizeBytes) async {
    // Prepare the list of files and their statistics.
    List<File> files = <File>[];
    Map<File, FileStat> fileStatMap = {};
    int currentSizeBytes = 0;
    List<FileSystemEntity> resources = new Directory(cachePath).listSync();
    for (FileSystemEntity resource in resources) {
      if (resource is File) {
        try {
          FileStat fileStat = await resource.stat();
          files.add(resource);
          fileStatMap[resource] = fileStat;
          currentSizeBytes += fileStat.size;
        } catch (_) {}
      }
    }
    files.sort((a, b) {
      return fileStatMap[a].accessed.millisecondsSinceEpoch -
          fileStatMap[b].accessed.millisecondsSinceEpoch;
    });

    // Delete files until the current size is less than the max.
    for (File file in files) {
      if (currentSizeBytes < maxSizeBytes) {
        break;
      }
      try {
        await file.delete();
      } catch (_) {}
      currentSizeBytes -= fileStatMap[file].size;
    }
  }
}

/**
 * [ByteStore] that stores values as files.
 */
class FileByteStore implements ByteStore {
  final String _cachePath;
  final String _tempName = 'temp_$pid';

  FileByteStore(this._cachePath);

  @override
  List<int> get(String key) {
    try {
      return _getFileForKey(key).readAsBytesSync();
    } catch (_) {
      return null;
    }
  }

  @override
  void put(String key, List<int> bytes) {
    try {
      File tempFile = _getFileForKey(_tempName);
      tempFile.writeAsBytesSync(bytes);
      File file = _getFileForKey(key);
      tempFile.renameSync(file.path);
    } catch (_) {}
  }

  File _getFileForKey(String key) {
    return new File(join(_cachePath, key));
  }
}
