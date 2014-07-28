// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.index.store.temporary_folder_file_mananer;

import 'dart:async';
import 'dart:io';

import 'package:analysis_services/src/index/store/split_store.dart';
import 'package:path/path.dart' as pathos;


/**
 * An implementation of [FileManager] that keeps each file in a separate file
 * in a temporary folder.
 */
class TemporaryFolderFileManager implements FileManager {
  Directory _directory;

  Directory get test_directory => _directory;

  @override
  void clear() {
    if (_directory != null) {
      _directory.deleteSync(recursive: true);
      _directory = null;
    }
  }

  @override
  void delete(String name) {
    if (_directory == null) {
      return;
    }
    File file = _getFile(name);
    try {
      file.deleteSync();
    } catch (e) {
    }
  }

  @override
  Future<List<int>> read(String name) {
    if (_directory == null) {
      return new Future.value(null);
    }
    File file = _getFile(name);
    return file.readAsBytes().catchError((e) {
      return null;
    });
  }

  @override
  Future write(String name, List<int> bytes) {
    _ensureDirectory();
    return _getFile(name).writeAsBytes(bytes);
  }

  void _ensureDirectory() {
    if (_directory == null) {
      Directory temp = Directory.systemTemp;
      _directory = temp.createTempSync('AnalysisServices_Index');
    }
  }

  File _getFile(String name) {
    String path = pathos.join(_directory.path, name);
    return new File(path);
  }
}
