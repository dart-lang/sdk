// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.src.index.store.separate_file_mananer;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/index/store/split_store.dart';
import 'package:path/path.dart' as pathos;


/**
 * An implementation of [FileManager] that keeps each file in a separate file
 * system file.
 */
class SeparateFileManager implements FileManager {
  final Directory _directory;

  SeparateFileManager(this._directory) {
    clear();
  }

  @override
  void clear() {
    List<FileSystemEntity> entries = _directory.listSync();
    for (FileSystemEntity entry in entries) {
      entry.deleteSync(recursive: true);
    }
  }

  @override
  void delete(String name) {
    File file = _getFile(name);
    try {
      file.deleteSync();
    } catch (e) {
    }
  }

  @override
  Future<List<int>> read(String name) {
    File file = _getFile(name);
    return file.readAsBytes().catchError((e) {
      return null;
    });
  }

  @override
  Future write(String name, List<int> bytes) {
    return _getFile(name).writeAsBytes(bytes);
  }

  File _getFile(String name) {
    String path = pathos.join(_directory.path, name);
    return new File(path);
  }
}
