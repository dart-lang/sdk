// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library index.file_page_manager;

import 'dart:io';
import 'dart:typed_data';

import 'package:analysis_server/src/index/page_node_manager.dart';


/**
 * A [PageManager] that stores pages on disk.
 */
class FilePageManager implements PageManager {
  final int pageSizeInBytes;

  RandomAccessFile _file;
  File _fileRef;
  List<int> _freePagesList = new List<int>();
  Set<int> _freePagesSet = new Set<int>();
  int _nextPage = 0;

  FilePageManager(this.pageSizeInBytes, String path) {
    _fileRef = new File(path);
    _file = _fileRef.openSync(mode: FileMode.WRITE);
  }

  @override
  int alloc() {
    if (_freePagesList.isNotEmpty) {
      int id = _freePagesList.removeLast();
      _freePagesSet.remove(id);
      return id;
    }
    int id = _nextPage++;
    Uint8List page = new Uint8List(pageSizeInBytes);
    _file.setPositionSync(id * pageSizeInBytes);
    _file.writeFromSync(page);
    return id;
  }

  /**
   * Closes this [FilePageManager].
   */
  void close() {
    _file.closeSync();
  }

  /**
   * Deletes the underlaying file.
   */
  void delete() {
    if (_fileRef.existsSync()) {
      _fileRef.deleteSync();
    }
  }

  @override
  void free(int id) {
    if (!_freePagesSet.add(id)) {
      throw new StateError('Page $id has been already freed.');
    }
    _freePagesList.add(id);
  }

  @override
  Uint8List read(int id) {
    Uint8List page = new Uint8List(pageSizeInBytes);
    _file.setPositionSync(id * pageSizeInBytes);
    int actual = 0;
    while (actual != page.length) {
      actual += _file.readIntoSync(page, actual);
    }
    return page;
  }

  @override
  void write(int id, Uint8List page) {
    _file.setPositionSync(id * pageSizeInBytes);
    _file.writeFromSync(page);
  }
}
