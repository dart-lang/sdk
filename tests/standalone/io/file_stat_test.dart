// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:io FileSystemEntity.Stat().

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

void testStat() {
  Directory directory = new Directory("").createTempSync();
  File file = new File.fromPath(new Path(directory.path).append("file"));
  FileStat nonExistent = FileStat.statSync(file.path);
  Expect.equals(FileSystemEntityType.NOT_FOUND, nonExistent.type);
  file.writeAsStringSync("Dart IO library test of FileStat");
  new Timer(const Duration(seconds: 2), () {
    file.readAsStringSync();
    directory.listSync();
    FileStat fileStat = FileStat.statSync(file.path);
    FileStat fileStatDirect = file.statSync();
    Expect.equals(FileSystemEntityType.FILE, fileStat.type);
    Expect.equals(32, fileStat.size);
    Expect.equals(FileSystemEntityType.FILE, fileStatDirect.type);
    Expect.equals(32, fileStatDirect.size);
    if (Platform.operatingSystem != 'windows') {
      Expect.isTrue(fileStat.modified.compareTo(fileStat.accessed) < 0);
      Expect.isTrue(fileStat.changed.compareTo(fileStat.accessed) < 0);
    }
    Expect.equals(6 << 6, fileStat.mode & (6 << 6));  // Mode includes +urw.
    FileStat directoryStat = FileStat.statSync(directory.path);
    FileStat directoryStatDirect = directory.statSync();
    Expect.equals(FileSystemEntityType.DIRECTORY, directoryStat.type);
    Expect.equals(FileSystemEntityType.DIRECTORY, directoryStatDirect.type);
    if (Platform.operatingSystem != 'windows') {
      Expect.isTrue(
          directoryStat.modified.compareTo(directoryStat.accessed) < 0);
      Expect.isTrue(
          directoryStat.changed.compareTo(directoryStat.accessed) < 0);
    }
    Expect.equals(7 << 6, directoryStat.mode & (7 << 6));  // Includes +urwx.
    directory.deleteSync(recursive: true);
  });
}


Future testStatAsync() {
  return new Directory("").createTemp()
  .then((directory) {
    File file = new File.fromPath(new Path(directory.path).append("file"));
    return FileStat.stat(file.path)
    .then((missingStat) {
      Expect.equals(FileSystemEntityType.NOT_FOUND, missingStat.type);
    })
    .then((_) => file.writeAsString("Dart IO library test of FileStat"))
    .then((_) => new Future.delayed(const Duration(seconds: 2)))
    .then((_) => file.readAsString())
    .then((_) => directory.list().last)
    .then((_) => FileStat.stat(file.path))
    .then((FileStat fileStat) {
      Expect.equals(FileSystemEntityType.FILE, fileStat.type);
      Expect.equals(32, fileStat.size);
      if (Platform.operatingSystem != 'windows') {
        Expect.isTrue(fileStat.modified.compareTo(fileStat.accessed) < 0);
        Expect.isTrue(fileStat.changed.compareTo(fileStat.accessed) < 0);
      }
      Expect.equals(6 << 6, fileStat.mode & (6 << 6));  // Mode includes +urw.
      return file.stat();
    })
    .then((FileStat fileStat) {
      Expect.equals(FileSystemEntityType.FILE, fileStat.type);
      Expect.equals(32, fileStat.size);
      if (Platform.operatingSystem != 'windows') {
        Expect.isTrue(fileStat.modified.compareTo(fileStat.accessed) < 0);
        Expect.isTrue(fileStat.changed.compareTo(fileStat.accessed) < 0);
      }
      Expect.equals(6 << 6, fileStat.mode & (6 << 6));  // Mode includes +urw.
      return FileStat.stat(directory.path);
    })
    .then((FileStat directoryStat) {
      Expect.equals(FileSystemEntityType.DIRECTORY, directoryStat.type);
      if (Platform.operatingSystem != 'windows') {
        Expect.isTrue(
            directoryStat.modified.compareTo(directoryStat.accessed) < 0);
        Expect.isTrue(
            directoryStat.changed.compareTo(directoryStat.accessed) < 0);
      }
      Expect.equals(7 << 6, directoryStat.mode & (7 << 6));  // Includes +urwx.
      return directory.stat();
    })
    .then((FileStat directoryStat) {
      Expect.equals(FileSystemEntityType.DIRECTORY, directoryStat.type);
      if (Platform.operatingSystem != 'windows') {
        Expect.isTrue(
            directoryStat.modified.compareTo(directoryStat.accessed) < 0);
        Expect.isTrue(
            directoryStat.changed.compareTo(directoryStat.accessed) < 0);
      }
      Expect.equals(7 << 6, directoryStat.mode & (7 << 6));  // Includes +urwx.
      return new Link(directory.path).stat();
    })
    .then((FileStat linkStat) {
      Expect.equals(FileSystemEntityType.DIRECTORY, linkStat.type);
      if (Platform.operatingSystem != 'windows') {
        Expect.isTrue(
            linkStat.modified.compareTo(linkStat.accessed) < 0);
        Expect.isTrue(
            linkStat.changed.compareTo(linkStat.accessed) < 0);
      }
      Expect.equals(7 << 6, linkStat.mode & (7 << 6));  // Includes +urwx.
      return directory.delete(recursive: true);
    });
  });
}


void main() {
  ReceivePort keepAlive = new ReceivePort();
  testStat();
  testStatAsync().then((_) => keepAlive.close());
}
