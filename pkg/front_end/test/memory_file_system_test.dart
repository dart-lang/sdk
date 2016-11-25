// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

library front_end.test.memory_file_system_test;

import 'dart:convert';
import 'dart:io' as io;

import 'package:front_end/memory_file_system.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemoryFileSystemTestNative);
    defineReflectiveTests(MemoryFileSystemTestPosix);
    defineReflectiveTests(MemoryFileSystemTestWindows);
    defineReflectiveTests(FileTest);
  });
}

@reflectiveTest
class FileTest extends _BaseTestNative {
  String path;
  MemoryFileSystemEntity file;

  setUp() {
    super.setUp();
    path = join(tempPath, 'file.txt');
    file = fileSystem.entityForPath(path);
  }

  test_equals_differentPaths() {
    expect(
        file == fileSystem.entityForPath(join(tempPath, 'file2.txt')), isFalse);
  }

  test_equals_samePath() {
    expect(
        file == fileSystem.entityForPath(join(tempPath, 'file.txt')), isTrue);
  }

  test_hashCode_samePath() {
    expect(file.hashCode,
        fileSystem.entityForPath(join(tempPath, 'file.txt')).hashCode);
  }

  test_path() {
    expect(file.path, path);
  }

  test_readAsBytes_badUtf8() async {
    // A file containing invalid UTF-8 can still be read as raw bytes.
    List<int> bytes = [0xc0, 0x40]; // Invalid UTF-8
    file.writeAsBytesSync(bytes);
    expect(await file.readAsBytes(), bytes);
  }

  test_readAsBytes_doesNotExist() {
    expect(file.readAsBytes(), throwsException);
  }

  test_readAsBytes_exists() async {
    var s = 'contents';
    file.writeAsStringSync(s);
    expect(await file.readAsBytes(), UTF8.encode(s));
  }

  test_readAsString_badUtf8() {
    file.writeAsBytesSync([0xc0, 0x40]); // Invalid UTF-8
    expect(file.readAsString(), throwsException);
  }

  test_readAsString_doesNotExist() {
    expect(file.readAsString(), throwsException);
  }

  test_readAsString_exists() async {
    var s = 'contents';
    file.writeAsStringSync(s);
    expect(await file.readAsString(), s);
  }

  test_readAsString_utf8() async {
    file.writeAsBytesSync([0xe2, 0x82, 0xac]); // Unicode € symbol, in UTF-8
    expect(await file.readAsString(), '\u20ac');
  }

  test_writeAsBytesSync_modifyAfterRead() async {
    file.writeAsBytesSync([1]);
    (await file.readAsBytes())[0] = 2;
    expect(await file.readAsBytes(), [1]);
  }

  test_writeAsBytesSync_modifyAfterWrite() async {
    var bytes = [1];
    file.writeAsBytesSync(bytes);
    bytes[0] = 2;
    expect(await file.readAsBytes(), [1]);
  }

  test_writeAsBytesSync_overwrite() async {
    file.writeAsBytesSync([1]);
    file.writeAsBytesSync([2]);
    expect(await file.readAsBytes(), [2]);
  }

  test_writeAsStringSync_overwrite() async {
    file.writeAsStringSync('first');
    file.writeAsStringSync('second');
    expect(await file.readAsString(), 'second');
  }

  test_writeAsStringSync_utf8() async {
    file.writeAsStringSync('\u20ac'); // Unicode € symbol
    expect(await file.readAsBytes(), [0xe2, 0x82, 0xac]);
  }
}

abstract class MemoryFileSystemTestMixin extends _BaseTest {
  Uri tempUri;

  setUp() {
    super.setUp();
    tempUri = fileSystem.context.toUri(tempPath);
  }

  test_entityForPath() {
    var path = join(tempPath, 'file.txt');
    expect(fileSystem.entityForPath(path).path, path);
  }

  test_entityForPath_absolutize() {
    expect(fileSystem.entityForPath('file.txt').path,
        join(fileSystem.currentDirectory, 'file.txt'));
  }

  test_entityForPath_normalize_dot() {
    expect(fileSystem.entityForPath(join(tempPath, '.', 'file.txt')).path,
        join(tempPath, 'file.txt'));
  }

  test_entityForPath_normalize_dotDot() {
    expect(
        fileSystem.entityForPath(join(tempPath, 'foo', '..', 'file.txt')).path,
        join(tempPath, 'file.txt'));
  }

  test_entityForUri() {
    expect(fileSystem.entityForUri(Uri.parse('$tempUri/file.txt')).path,
        join(tempPath, 'file.txt'));
  }

  test_entityForUri_bareUri_absolute() {
    expect(() => fileSystem.entityForUri(Uri.parse('/file.txt')),
        throwsA(new isInstanceOf<Error>()));
  }

  test_entityForUri_bareUri_relative() {
    expect(() => fileSystem.entityForUri(Uri.parse('file.txt')),
        throwsA(new isInstanceOf<Error>()));
  }

  test_entityForUri_fileUri_relative() {
    // A weird quirk of the Uri class is that it doesn't seem possible to create
    // a `file:` uri with a relative path, no matter how many slashes you use or
    // if you populate the fields directly.  But just to be certain, try to do
    // so, and make that `file:` uris with relative paths are rejected.
    for (var uri in <Uri>[
      new Uri(scheme: 'file', path: 'file.txt'),
      Uri.parse('file:file.txt'),
      Uri.parse('file:/file.txt'),
      Uri.parse('file://file.txt'),
      Uri.parse('file:///file.txt')
    ]) {
      if (!uri.path.startsWith('/')) {
        expect(() => fileSystem.entityForUri(uri),
            throwsA(new isInstanceOf<Error>()));
      }
    }
  }

  test_entityForUri_nonFileUri() {
    expect(() => fileSystem.entityForUri(Uri.parse('package:foo/bar.dart')),
        throwsA(new isInstanceOf<Error>()));
  }

  test_entityForUri_normalize_dot() {
    expect(fileSystem.entityForUri(Uri.parse('$tempUri/./file.txt')).path,
        join(tempPath, 'file.txt'));
  }

  test_entityForUri_normalize_dotDot() {
    expect(fileSystem.entityForUri(Uri.parse('$tempUri/foo/../file.txt')).path,
        join(tempPath, 'file.txt'));
  }
}

@reflectiveTest
class MemoryFileSystemTestNative extends _BaseTestNative
    with MemoryFileSystemTestMixin {}

@reflectiveTest
class MemoryFileSystemTestPosix extends _BaseTestPosix
    with MemoryFileSystemTestMixin {}

@reflectiveTest
class MemoryFileSystemTestWindows extends _BaseTestWindows
    with MemoryFileSystemTestMixin {}

abstract class _BaseTest {
  MemoryFileSystem get fileSystem;
  String get tempPath;
  String join(String path1, String path2, [String path3, String path4]);
  void setUp();
}

class _BaseTestNative extends _BaseTest {
  MemoryFileSystem fileSystem;
  String tempPath;

  String join(String path1, String path2, [String path3, String path4]) =>
      pathos.join(path1, path2, path3, path4);

  setUp() {
    tempPath = pathos.join(io.Directory.systemTemp.path, 'test_file_system');
    fileSystem =
        new MemoryFileSystem(pathos.context, io.Directory.current.path);
  }
}

class _BaseTestPosix extends _BaseTest {
  MemoryFileSystem fileSystem;
  String tempPath;

  String join(String path1, String path2, [String path3, String path4]) =>
      pathos.posix.join(path1, path2, path3, path4);

  void setUp() {
    tempPath = '/test_file_system';
    fileSystem = new MemoryFileSystem(pathos.posix, '/cwd');
  }
}

class _BaseTestWindows extends _BaseTest {
  MemoryFileSystem fileSystem;
  String tempPath;

  String join(String path1, String path2, [String path3, String path4]) =>
      pathos.windows.join(path1, path2, path3, path4);

  void setUp() {
    tempPath = r'c:\test_file_system';
    fileSystem = new MemoryFileSystem(pathos.windows, r'c:\cwd');
  }
}
