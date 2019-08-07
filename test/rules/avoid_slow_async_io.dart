// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_slow_async_io`

import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

Future<Null> some_File_lastModified() async {
  var file = new File('/path/to/my/file');
  var now = new DateTime.now();
  if ((await file.lastModified()).isBefore(now)) print('before'); // LINT
}

Future<Null> some_File_lastModifiedSync() async {
  var file = new File('/path/to/my/file');
  var now = new DateTime.now();
  if (file.lastModifiedSync().isBefore(now)) print('before'); // OK
}

Future<Null> some_File_exists() async {
  var file = new File('/path/to/my/file');
  if (await file.exists()) print('exists'); // LINT
}

Future<Null> some_File_existsSync() async {
  var file = new File('/path/to/my/file');
  if (file.existsSync()) print('before'); // OK
}

Future<Null> some_File_stat() async {
  var file = new File('/path/to/my/file');
  if (await file.stat() == null) print('stat'); // LINT
}

Future<Null> some_File_statSync() async {
  var file = new File('/path/to/my/file');
  if (file.statSync() == null) print('stat'); // OK
}

Future<Null> some_FileSystemEntity_isDirectory() async {
  String path = '/path/to/my/file/entity';
  if (await FileSystemEntity.isDirectory(path)) print('dir'); // LINT
}

Future<Null> some_FileSystemEntity_isDirectorySync() async {
  String path = '/path/to/my/file/entity';
  if (FileSystemEntity.isDirectorySync(path)) print('dir'); // OK
}

Future<Null> some_FileSystemEntity_isFile() async {
  String path = '/path/to/my/file/entity';
  if (await io.FileSystemEntity.isFile(path)) print('file'); // LINT
}

Future<Null> some_FileSystemEntity_isFileSync() async {
  String path = '/path/to/my/file/entity';
  if (io.FileSystemEntity.isFileSync(path)) print('file'); // OK
}

Future<Null> some_FileSystemEntity_isLink() async {
  String path = '/path/to/my/file/entity';
  if (await FileSystemEntity.isLink(path)) print('link'); // LINT
}

Future<Null> some_FileSystemEntity_isLinkSync() async {
  String path = '/path/to/my/file/entity';
  if (FileSystemEntity.isLinkSync(path)) print('link'); // OK
}

Future<Null> some_FileSystemEntity_type() async {
  String path = '/path/to/my/file/entity';
  if (FileSystemEntity.type(path) == null) {} // LINT
}

Future<Null> some_FileSystemEntity_type2() async {
  String path = '/path/to/my/file/entity';
  if (FileSystemEntity.type(path, followLinks: true) == null) {} // LINT
}

Future<Null> some_FileSystemEntity_typeSync() async {
  String path = '/path/to/my/file/entity';
  if (FileSystemEntity.typeSync(path) == null) {} // OK
}

Future<Null> some_FileSystemEntity_typeSync2() async {
  String path = '/path/to/my/file/entity';
  if (FileSystemEntity.typeSync(path, followLinks: true) == null) {} // OK
}

Future<Null> some_Directory_exists() async {
  var dir = Directory('/path/to/my/dir');
  if (await dir.exists()) print('exists'); // LINT
}

Future<Null> some_Directory_existsSync() async {
  var dir = Directory('/path/to/my/dir');
  if (dir.existsSync()) print('before'); // OK
}

Future<Null> some_Directory_stat() async {
  var dir = Directory('/path/to/my/file');
  if (await dir.stat() == null) print('stat'); // LINT
}

Future<Null> some_Directory_statSync() async {
  var dir = Directory('/path/to/my/dir');
  if (dir.statSync() == null) print('stat'); // OK
}
