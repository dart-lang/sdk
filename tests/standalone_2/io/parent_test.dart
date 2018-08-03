// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

String tempDirectory;

void main() {
  if (Platform.isWindows) {
    testWindowsCases();
  } else {
    testPosixCases();
  }
  asyncStart();
  createTempDirectories().then(testObjects).whenComplete(() {
    asyncEnd();
    new Directory(tempDirectory).delete(recursive: true);
  });
}

testPosixCases() {
  Expect.equals('/dir', FileSystemEntity.parentOf('/dir/file'));
  Expect.equals('/dir', FileSystemEntity.parentOf('/dir/file/'));
  Expect.equals('/dir', FileSystemEntity.parentOf('/dir//file//'));
  Expect.equals('/', FileSystemEntity.parentOf('/dir'));
  Expect.equals('/', FileSystemEntity.parentOf('/dir///'));
  Expect.equals('/', FileSystemEntity.parentOf('/'));

  Expect.equals('.', FileSystemEntity.parentOf('file'));
  Expect.equals('.', FileSystemEntity.parentOf('file//'));
  Expect.equals('.', FileSystemEntity.parentOf(''));
  Expect.equals('.', FileSystemEntity.parentOf('..'));
  Expect.equals('.', FileSystemEntity.parentOf('.'));
  Expect.equals('.', FileSystemEntity.parentOf(''));
  Expect.equals('/', FileSystemEntity.parentOf('/'));
  Expect.equals('/', FileSystemEntity.parentOf('//'));
  Expect.equals('/', FileSystemEntity.parentOf('//file///'));
  Expect.equals('dir', FileSystemEntity.parentOf('dir/file'));
  Expect.equals('dir', FileSystemEntity.parentOf('dir/file/'));
  Expect.equals('dir', FileSystemEntity.parentOf('dir/file//'));
  Expect.equals('dir/subdir', FileSystemEntity.parentOf('dir/subdir/file'));
  Expect.equals('dir//subdir', FileSystemEntity.parentOf('dir//subdir//file/'));
  Expect.equals(
      'dir/sub.dir', FileSystemEntity.parentOf('dir/sub.dir/fi le///'));
  Expect.equals('dir/..', FileSystemEntity.parentOf('dir/../file/'));
  Expect.equals('dir/..', FileSystemEntity.parentOf('dir/../..'));
  Expect.equals('.', FileSystemEntity.parentOf('./..'));
  Expect.equals('..', FileSystemEntity.parentOf('../.'));
}

testWindowsCases() {
  Expect.equals(r'C:/dir', FileSystemEntity.parentOf(r'C:/dir/file'));
  Expect.equals(r'C:/dir', FileSystemEntity.parentOf(r'C:/dir/file/'));
  Expect.equals(r'C:\dir', FileSystemEntity.parentOf(r'C:\dir\file'));
  Expect.equals(r'C:\dir', FileSystemEntity.parentOf(r'C:\dir\file\'));
  Expect.equals(r'C:\dir', FileSystemEntity.parentOf(r'C:\dir\\file\\'));
  Expect.equals(r'C:\', FileSystemEntity.parentOf(r'C:\dir'));
  Expect.equals(r'C:\', FileSystemEntity.parentOf(r'C:\dir\/\'));
  Expect.equals(r'C:\', FileSystemEntity.parentOf(r'C:\'));
  // FileSystemEntity.isAbsolute returns false for 'C:'.
  Expect.equals(r'.', FileSystemEntity.parentOf(r'C:'));

  Expect.equals(r'\\server\share\dir',
      FileSystemEntity.parentOf(r'\\server\share\dir\file'));
  Expect.equals(r'\\server\share\dir',
      FileSystemEntity.parentOf(r'\\server\share\dir\file\'));
  Expect.equals(
      r'\\server\share', FileSystemEntity.parentOf(r'\\server\share\file'));
  Expect.equals(r'\\server\', FileSystemEntity.parentOf(r'\\server\share'));
  Expect.equals(r'\\server\', FileSystemEntity.parentOf(r'\\server\share\'));
  Expect.equals(r'\\server\', FileSystemEntity.parentOf(r'\\server\'));
  Expect.equals(r'\\server/', FileSystemEntity.parentOf(r'\\server/'));
  Expect.equals(r'\\serve', FileSystemEntity.parentOf(r'\\serve'));

  Expect.equals(r'.', FileSystemEntity.parentOf(r'file'));
  Expect.equals(r'.', FileSystemEntity.parentOf(r''));
  Expect.equals(r'.', FileSystemEntity.parentOf(r'..'));
  Expect.equals(r'.', FileSystemEntity.parentOf(r'.'));
  Expect.equals(r'.', FileSystemEntity.parentOf(r''));
  Expect.equals(r'/', FileSystemEntity.parentOf(r'/'));
  Expect.equals(r'\', FileSystemEntity.parentOf(r'\'));
  Expect.equals(r'\', FileSystemEntity.parentOf(r'\file\\/'));
  Expect.equals(r'dir', FileSystemEntity.parentOf(r'dir\file'));
  Expect.equals(r'dir', FileSystemEntity.parentOf(r'dir\file\'));
  Expect.equals(r'dir', FileSystemEntity.parentOf(r'dir/file/'));
  Expect.equals(r'dir\subdir', FileSystemEntity.parentOf(r'dir\subdir\file'));
  Expect.equals(
      r'dir\sub.dir', FileSystemEntity.parentOf(r'dir\sub.dir\fi le'));
}

Future createTempDirectories() {
  return Directory.systemTemp
      .createTemp('dart_parent_')
      .then((dir) {
        tempDirectory = dir.path;
      })
      .then((_) => new File(join(tempDirectory, 'file1')).create())
      .then((_) => new Link(join(tempDirectory, 'link1')).create('.'))
      .then((_) => new Directory(join(tempDirectory, 'dir1')).create());
}

testObjects(var ignored) {
  ['file1', 'link1', 'dir1', 'file2', 'link2', 'dir2'].map(testPath);
}

testPath(String path) {
  Expect.equals(tempDirectory, new File(join(tempDirectory, path)).parent.path);
  Expect.equals(tempDirectory, new Link(join(tempDirectory, path)).parent.path);
  Expect.equals(
      tempDirectory, new Directory(join(tempDirectory, path)).parent.path);
}
