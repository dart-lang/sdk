// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

class DirectoryMock extends FileSystemEntity implements Directory {
  static final _mockUri = Uri.parse('http:///mockdir/');
  final String path;

  DirectoryMock(this.path);

  static DirectoryMock _currentDirectory = DirectoryMock("");

  static DirectoryMock createDirectory(String path) => new DirectoryMock(path);
  static DirectoryMock getCurrent() => _currentDirectory;
  static void setCurrent(String path) =>
      _currentDirectory = DirectoryMock(path);
  static DirectoryMock getSystemTemp() => new DirectoryMock("");
  Uri get uri => _mockUri;

  Future<Directory> create({bool recursive = false}) => throw "";
  void createSync({bool recursive = false}) {}
  Future<Directory> createTemp([String? prefix]) => throw "";
  Directory createTempSync([String? prefix]) => throw "";
  Future<bool> exists() => throw "";
  bool existsSync() => false;
  Future<String> resolveSymbolicLinks() => throw "";
  String resolveSymbolicLinksSync() => throw "";
  Future<Directory> rename(String newPath) => throw "";
  Directory renameSync(String newPath) => throw "";
  Directory get absolute => throw "";
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => throw "";
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) => throw "";
}

class FileMock extends FileSystemEntity implements File {
  String get path => "/mockfile";

  FileMock(String path);

  static FileMock createFile(String path) => new FileMock(path);

  Future<File> create({bool recursive = false, bool exclusive = false}) =>
      throw "";
  void createSync({bool recursive = false, bool exclusive = false}) {}
  Future<File> rename(String newPath) => throw "";
  File renameSync(String newPath) => throw "";
  Future<File> copy(String newPath) => throw "";
  File copySync(String newPath) => throw "";
  Future<bool> exists() => throw "";
  bool existsSync() => false;
  Future<int> length() => throw "";
  int lengthSync() => throw "";
  File get absolute => throw "";
  Future<DateTime> lastAccessed() => throw "";
  DateTime lastAccessedSync() => throw "";
  Future setLastAccessed(DateTime time) => throw "";
  void setLastAccessedSync(DateTime time) {}
  Future<DateTime> lastModified() => throw "";
  DateTime lastModifiedSync() => throw "";
  Future setLastModified(DateTime time) => throw "";
  void setLastModifiedSync(DateTime time) {}
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) => throw "";
  RandomAccessFile openSync({FileMode mode = FileMode.read}) => throw "";
  Stream<List<int>> openRead([int? start, int? end]) => throw "";
  IOSink openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) => throw "";
  Future<Uint8List> readAsBytes() => throw "";
  Uint8List readAsBytesSync() => throw "";
  Future<String> readAsString({Encoding encoding = utf8}) => throw "";
  String readAsStringSync({Encoding encoding = utf8}) => throw "";
  Future<List<String>> readAsLines({Encoding encoding = utf8}) => throw "";
  List<String> readAsLinesSync({Encoding encoding = utf8}) => throw "";
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) => throw "";
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {}
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => throw "";
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {}
}

class FileStatMock implements FileStat {
  final changed = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final modified = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final accessed = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final type = FileSystemEntityType.file;
  final int mode = 0;
  final int size = 0;

  FileStatMock();

  static Future<FileStat> stat(String path) {
    return new Future.value(new FileStatMock());
  }

  static FileStat statSync(String path) => new FileStatMock();

  String modeString() => throw "";
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

final _mockFileSystemEvent = new Stream<FileSystemEvent>.empty();

class FileSystemWatcherMock {
  static Stream<FileSystemEvent> watch(
    String path,
    int events,
    bool recursive,
  ) => _mockFileSystemEvent;

  static bool watchSupported() => false;
}

class LinkMock extends FileSystemEntity implements Link {
  String get path => "/mocklink";

  LinkMock(String path);

  static Link createLink(String path) => new LinkMock(path);

  Future<Link> create(String target, {bool recursive = false}) => throw "";
  void createSync(String target, {bool recursive = false}) {}
  void updateSync(String target) {}
  Future<Link> update(String target) => throw "";
  Future<bool> exists() => throw "";
  bool existsSync() => false;
  Future<String> resolveSymbolicLinks() => throw "";
  String resolveSymbolicLinksSync() => throw "";
  Future<Link> rename(String newPath) => throw "";
  Link renameSync(String newPath) => throw "";
  Link get absolute => throw "";
  Future<String> target() => throw "";
  String targetSync() => throw "";
}

Future<Socket> socketConnect(
  dynamic host,
  int port, {
  dynamic sourceAddress,
  int sourcePort = 0,
  Duration? timeout,
}) async {
  throw "";
}

Future<ConnectionTask<Socket>> socketStartConnect(
  dynamic host,
  int port, {
  dynamic sourceAddress,
  int sourcePort = 0,
}) async {
  throw "";
}

Future<ServerSocket> serverSocketBind(
  dynamic address,
  int port, {
  int backlog = 0,
  bool v6Only = false,
  bool shared = false,
}) async {
  throw "";
}

class StdinMock extends Stream<List<int>> implements Stdin {
  bool echoMode = false;
  bool echoNewlineMode = false;
  bool lineMode = false;
  bool get hasTerminal => throw "";
  bool get supportsAnsiEscapes => throw "";

  int readByteSync() => throw "";
  String readLineSync({
    Encoding encoding = systemEncoding,
    bool retainNewlines = false,
  }) => throw "";
  StreamSubscription<List<int>> listen(
    void onData(List<int> event)?, {
    Function? onError,
    void onDone()?,
    bool? cancelOnError,
  }) {
    throw "";
  }
}

class StdoutMock implements Stdout {
  Never noSuchMethod(Invocation i) => throw "";
}

Future<Null> ioOverridesRunTest() async {
  StdoutMock stdoutMock = StdoutMock();
  StdoutMock stderrMock = StdoutMock();

  Future<Null> f = IOOverrides.runZoned(
    () async {
      Expect.isTrue(new Directory("directory") is DirectoryMock);
      Expect.isTrue(Directory.current is DirectoryMock);

      const mockDirectoryPath1 = "/mockDirectory1";
      const mockDirectoryPath2 = "/mockDirectory2";

      Directory.current = mockDirectoryPath1;
      Expect.isTrue(Directory.current.path == mockDirectoryPath1);
      Directory.current = Directory(mockDirectoryPath2);
      Expect.isTrue(Directory.current.path == mockDirectoryPath2);

      Expect.identical(Uri.base, DirectoryMock._mockUri);
      Expect.isTrue(Directory.systemTemp is DirectoryMock);
      Expect.isTrue(new File("file") is FileMock);
      Expect.isTrue(await FileStat.stat("file") is FileStatMock);
      Expect.isTrue(FileStat.statSync("file") is FileStatMock);
      Expect.isFalse(await FileSystemEntity.identical("file", "file"));
      Expect.isFalse(FileSystemEntity.identicalSync("file", "file"));
      Expect.equals(
        await FileSystemEntity.type("file"),
        FileSystemEntityType.file,
      );
      Expect.equals(
        FileSystemEntity.typeSync("file"),
        FileSystemEntityType.file,
      );
      Expect.isFalse(FileSystemEntity.isWatchSupported);
      Expect.identical(
        _mockFileSystemEvent,
        new Directory("directory").watch(),
      );
      Expect.isTrue(new Link("link") is LinkMock);
      asyncExpectThrows(Socket.connect(null, 0));
      asyncExpectThrows(Socket.startConnect(null, 0));
      asyncExpectThrows(ServerSocket.bind(null, 0));
      Expect.isTrue(stdin is StdinMock);
      Expect.identical(stdout, stdoutMock);
      Expect.identical(stderr, stderrMock);
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
    stdin: () => StdinMock(),
    stdout: () => stdoutMock,
    stderr: () => stderrMock,
  );
  Expect.isFalse(new Directory("directory") is DirectoryMock);
  Expect.isTrue(new Directory("directory") is Directory);
  await f;
}

final class MyIOOverrides extends IOOverrides {
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

final class EmptyOverride extends IOOverrides {}

void emptyIOOverride() {
  IOOverrides.runWithIOOverrides(
    () => Expect.equals(
      FileSystemEntity.typeSync('/'),
      FileSystemEntityType.directory,
    ),
    EmptyOverride(),
  );
}

main() async {
  await ioOverridesRunTest();
  globalIOOverridesTest();
  globalIOOverridesZoneTest();
  emptyIOOverride();
}
