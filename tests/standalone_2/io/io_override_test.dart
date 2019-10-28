// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import "package:expect/expect.dart";

class DirectoryMock extends FileSystemEntity implements Directory {
  final String path = "/mockdir";

  DirectoryMock(String path);

  static DirectoryMock createDirectory(String path) => new DirectoryMock(path);
  static DirectoryMock getCurrent() => new DirectoryMock(null);
  static void setCurrent(String path) {}
  static DirectoryMock getSystemTemp() => new DirectoryMock(null);

  Uri get uri => null;
  Future<Directory> create({bool recursive: false}) => null;
  void createSync({bool recursive: false}) {}
  Future<Directory> createTemp([String prefix]) => null;
  Directory createTempSync([String prefix]) => null;
  Future<bool> exists() => null;
  bool existsSync() => false;
  Future<String> resolveSymbolicLinks() => null;
  String resolveSymbolicLinksSync() => null;
  Future<Directory> rename(String newPath) => null;
  Directory renameSync(String newPath) => null;
  Directory get absolute => null;
  Stream<FileSystemEntity> list(
          {bool recursive: false, bool followLinks: true}) =>
      null;
  List<FileSystemEntity> listSync(
          {bool recursive: false, bool followLinks: true}) =>
      null;
}

class FileMock extends FileSystemEntity implements File {
  String get path => "/mockfile";

  FileMock(String path);

  static FileMock createFile(String path) => new FileMock(path);

  Future<File> create({bool recursive: false}) => null;
  void createSync({bool recursive: false}) {}
  Future<File> rename(String newPath) => null;
  File renameSync(String newPath) => null;
  Future<File> copy(String newPath) => null;
  File copySync(String newPath) => null;
  Future<bool> exists() => null;
  bool existsSync() => false;
  Future<int> length() => null;
  int lengthSync() => null;
  File get absolute => null;
  Future<DateTime> lastAccessed() => null;
  DateTime lastAccessedSync() => null;
  Future setLastAccessed(DateTime time) => null;
  void setLastAccessedSync(DateTime time) {}
  Future<DateTime> lastModified() => null;
  DateTime lastModifiedSync() => null;
  Future setLastModified(DateTime time) => null;
  void setLastModifiedSync(DateTime time) {}
  Future<RandomAccessFile> open({FileMode mode: FileMode.read}) => null;
  RandomAccessFile openSync({FileMode mode: FileMode.read}) => null;
  Stream<List<int>> openRead([int start, int end]) => null;
  IOSink openWrite({FileMode mode: FileMode.write, Encoding encoding: utf8}) =>
      null;
  Future<Uint8List> readAsBytes() => null;
  Uint8List readAsBytesSync() => null;
  Future<String> readAsString({Encoding encoding: utf8}) => null;
  String readAsStringSync({Encoding encoding: utf8}) => null;
  Future<List<String>> readAsLines({Encoding encoding: utf8}) => null;
  List<String> readAsLinesSync({Encoding encoding: utf8}) => null;
  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode: FileMode.write, bool flush: false}) =>
      null;
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode: FileMode.write, bool flush: false}) {}
  Future<File> writeAsString(String contents,
          {FileMode mode: FileMode.write,
          Encoding encoding: utf8,
          bool flush: false}) =>
      null;
  void writeAsStringSync(String contents,
      {FileMode mode: FileMode.write,
      Encoding encoding: utf8,
      bool flush: false}) {}
}

class FileStatMock implements FileStat {
  final DateTime changed = null;
  final DateTime modified = null;
  final DateTime accessed = null;
  final FileSystemEntityType type = null;
  final int mode = null;
  final int size = null;

  FileStatMock();

  static Future<FileStat> stat(String path) {
    return new Future.value(new FileStatMock());
  }

  static FileStat statSync(String path) => new FileStatMock();

  String modeString() => null;
}

class FileSystemEntityMock {
  static Future<bool> identical(String path1, String path2) {
    return new Future.value(false);
  }

  static bool identicalSync(String path1, String path2) => false;

  static Future<FileSystemEntityType> getType(String path, bool followLinks) {
    return new Future.value(FileSystemEntityType.file);
  }

  static FileSystemEntityType getTypeSync(String path, bool followLinks) {
    return FileSystemEntityType.file;
  }
}

class FileSystemWatcherMock {
  static Stream<FileSystemEvent> watch(
      String path, int events, bool recursive) {
    return null;
  }

  static bool watchSupported() => false;
}

class LinkMock extends FileSystemEntity implements Link {
  String get path => "/mocklink";

  LinkMock(String path);

  static Link createLink(String path) => new LinkMock(path);

  Future<Link> create(String target, {bool recursive: false}) => null;
  void createSync(String target, {bool recursive: false}) {}
  void updateSync(String target) {}
  Future<Link> update(String target) => null;
  Future<bool> exists() => null;
  bool existsSync() => false;
  Future<String> resolveSymbolicLinks() => null;
  String resolveSymbolicLinksSync() => null;
  Future<Link> rename(String newPath) => null;
  Link renameSync(String newPath) => null;
  Link get absolute => null;
  Future<String> target() => null;
  String targetSync() => null;
}

Future<Socket> socketConnect(host, int port,
    {sourceAddress, Duration timeout}) {
  return null;
}

Future<ConnectionTask<Socket>> socketStartConnect(host, int port,
    {sourceAddress}) {
  return null;
}

Future<ServerSocket> serverSocketBind(address, int port,
    {int backlog: 0, bool v6Only: false, bool shared: false}) {
  return null;
}

Future<Null> ioOverridesRunTest() async {
  Future<Null> f = IOOverrides.runZoned(
    () async {
      Expect.isTrue(new Directory("directory") is DirectoryMock);
      Expect.isTrue(Directory.current is DirectoryMock);
      Expect.isTrue(Directory.systemTemp is DirectoryMock);
      Expect.isTrue(new File("file") is FileMock);
      Expect.isTrue(await FileStat.stat("file") is FileStatMock);
      Expect.isTrue(FileStat.statSync("file") is FileStatMock);
      Expect.isFalse(await FileSystemEntity.identical("file", "file"));
      Expect.isFalse(FileSystemEntity.identicalSync("file", "file"));
      Expect.equals(
          await FileSystemEntity.type("file"), FileSystemEntityType.file);
      Expect.equals(
          FileSystemEntity.typeSync("file"), FileSystemEntityType.file);
      Expect.isFalse(FileSystemEntity.isWatchSupported);
      Expect.isNull(new Directory("directory").watch());
      Expect.isTrue(new Link("link") is LinkMock);
      Expect.isNull(Socket.connect(null, 0));
      Expect.isNull(Socket.startConnect(null, 0));
      Expect.isNull(ServerSocket.bind(null, 0));
    },
    createDirectory: DirectoryMock.createDirectory,
    getCurrentDirectory: DirectoryMock.getCurrent,
    setCurrentDirectory: DirectoryMock.setCurrent,
    getSystemTempDirectory: DirectoryMock.getSystemTemp,
    createFile: FileMock.createFile,
    stat: FileStatMock.stat,
    statSync: FileStatMock.statSync,
    fseIdentical: FileSystemEntityMock.identical,
    fseIdenticalSync: FileSystemEntityMock.identicalSync,
    fseGetType: FileSystemEntityMock.getType,
    fseGetTypeSync: FileSystemEntityMock.getTypeSync,
    fsWatch: FileSystemWatcherMock.watch,
    fsWatchIsSupported: FileSystemWatcherMock.watchSupported,
    createLink: LinkMock.createLink,
    socketConnect: socketConnect,
    socketStartConnect: socketStartConnect,
    serverSocketBind: serverSocketBind,
  );
  Expect.isFalse(new Directory("directory") is DirectoryMock);
  Expect.isTrue(new Directory("directory") is Directory);
  await f;
}

class MyIOOverrides extends IOOverrides {
  Directory createDirectory(String path) => DirectoryMock.createDirectory(path);
}

globalIOOverridesTest() {
  IOOverrides.global = new MyIOOverrides();
  Expect.isTrue(new Directory("directory") is DirectoryMock);
  IOOverrides.global = null;
  Directory dir = new Directory("directory");
  Expect.isTrue(dir is! DirectoryMock);
  Expect.isTrue(dir is Directory);
}

globalIOOverridesZoneTest() {
  IOOverrides.global = new MyIOOverrides();
  runZoned(() {
    runZoned(() {
      Expect.isTrue(new Directory("directory") is DirectoryMock);
    });
  });
  IOOverrides.global = null;
  Directory dir = new Directory("directory");
  Expect.isTrue(dir is! DirectoryMock);
  Expect.isTrue(dir is Directory);
}

main() async {
  await ioOverridesRunTest();
  globalIOOverridesTest();
  globalIOOverridesZoneTest();
}
