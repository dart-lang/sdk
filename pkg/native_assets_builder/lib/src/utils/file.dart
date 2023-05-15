// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

extension FileExtension on File {
  Future<File> writeAsStringCreateDirectory(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) async {
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    return await writeAsString(contents,
        mode: mode, encoding: encoding, flush: flush);
  }
}

extension FileSystemEntityExtension on FileSystemEntity {
  Future<DateTime> lastModified() async {
    final this_ = this;
    if (this_ is Link || await FileSystemEntity.isLink(this_.path)) {
      // Don't follow links.
      return DateTime.fromMicrosecondsSinceEpoch(0);
    }
    if (this_ is File) {
      if (!await this_.exists()) {
        // If the file was deleted, regard it is modified recently.
        return DateTime.now();
      }
      return await this_.lastModified();
    }
    if (this_ is Directory) {
      return await this_.lastModified();
    }
    throw Exception('Unknown FileSystemEntity $runtimeType');
  }
}

extension FileSystemEntityIterable on Iterable<FileSystemEntity> {
  Future<DateTime> lastModified() async {
    var last = DateTime.fromMillisecondsSinceEpoch(0);
    for (final entity in this) {
      final entityTimestamp = await entity.lastModified();
      if (entityTimestamp.isAfter(last)) {
        last = entityTimestamp;
      }
    }
    return last;
  }
}

extension DirectoryExtension on Directory {
  Future<DateTime> lastModified() async {
    var last = DateTime.fromMillisecondsSinceEpoch(0);
    await for (final entity in list()) {
      final entityTimestamp = await entity.lastModified();
      if (entityTimestamp.isAfter(last)) {
        last = entityTimestamp;
      }
    }
    return last;
  }
}
