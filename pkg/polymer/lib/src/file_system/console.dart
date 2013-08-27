// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library console;

import 'dart:convert';
import 'dart:io';
import 'package:polymer/src/file_system.dart';

/** File system implementation for console VM (i.e. no browser). */
class ConsoleFileSystem implements FileSystem {

  /** Pending futures for file write requests. */
  final _pending = <String, Future>{};

  Future flush() => Future.wait(_pending.values.toList());

  void writeString(String path, String text) {
    if(!_pending.containsKey(path)) {
      _pending[path] = new File(path).open(mode: FileMode.WRITE)
          .then((file) => file.writeString(text))
          .then((file) => file.close())
          .whenComplete(() { _pending.remove(path); });
    }
  }

  // TODO(jmesserly): even better would be to pass the RandomAccessFile directly
  // to html5lib. This will require a further restructuring of FileSystem.
  // Probably it just needs "readHtml" and "readText" methods.
  Future<List<int>> readTextOrBytes(String path) {
    return new File(path).open().then(
        (file) => file.length().then((length) {
      // TODO(jmesserly): is this guaranteed to read all of the bytes?
      var buffer = new List<int>(length);
      return file.readInto(buffer, 0, length)
          .then((_) => file.close())
          .then((_) => buffer);
    }));
  }

  // TODO(jmesserly): do we support any encoding other than UTF-8 for Dart?
  Future<String> readText(String path) {
    return readTextOrBytes(path).then(UTF8.decode);
  }
}
