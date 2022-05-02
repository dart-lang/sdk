// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

class FileSystemEntityMock {
  static Future<FileSystemEntityType> getType(String path, bool followLinks) {
    Expect.equals(path.length, 4);
    return new Future.value(FileSystemEntityType.file);
  }

  static FileSystemEntityType getTypeSync(String path, bool followLinks) {
    Expect.equals(path.length, 4);
    return FileSystemEntityType.file;
  }
}

main() async {
  Future<Null> f = IOOverrides.runZoned(
    () async {
      Expect.equals(
          await FileSystemEntity.type("file"), FileSystemEntityType.file);
      Expect.equals(
          FileSystemEntity.typeSync("file"), FileSystemEntityType.file);
    },
    fseGetType: FileSystemEntityMock.getType,
    fseGetTypeSync: FileSystemEntityMock.getTypeSync,
  );
  await f;
}
