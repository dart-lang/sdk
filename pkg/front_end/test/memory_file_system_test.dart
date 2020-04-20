// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

library front_end.test.memory_file_system_test;

import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:front_end/src/api_prototype/file_system.dart'
    show FileSystemException;
import 'package:front_end/src/api_prototype/memory_file_system.dart';
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

final Matcher _throwsFileSystemException =
    throwsA(const TypeMatcher<FileSystemException>());

@reflectiveTest
class FileTest extends _BaseTestNative {
  String path;
  MemoryFileSystemEntity file;

  setUp() {
    _baseSetUp();
    path = join(tempPath, 'file.txt');
    file = entityForPath(path);
  }

  test_createDirectory_doesNotExist() async {
    file.createDirectory();
    expect(await file.exists(), true);
  }

  test_createDirectory_exists_asDirectory() async {
    file.createDirectory();
    file.createDirectory();
    expect(await file.exists(), true);
  }

  test_createDirectory_exists_asFile() async {
    file.writeAsStringSync('');
    expect(() => file.createDirectory(), _throwsFileSystemException);
  }

  test_equals_differentPaths() {
    expect(file == entityForPath(join(tempPath, 'file2.txt')), isFalse);
  }

  test_equals_samePath() {
    expect(file == entityForPath(join(tempPath, 'file.txt')), isTrue);
  }

  test_exists_directory_exists() async {
    file.createDirectory();
    expect(await file.exists(), true);
  }

  test_exists_doesNotExist() async {
    expect(await file.exists(), false);
  }

  test_exists_file_exists() async {
    file.writeAsStringSync('x');
    expect(await file.exists(), true);
  }

  test_hashCode_samePath() {
    expect(file.hashCode, entityForPath(join(tempPath, 'file.txt')).hashCode);
  }

  test_path() {
    expect(file.uri, context.toUri(path));
  }

  test_readAsBytes_badUtf8() async {
    // A file containing invalid UTF-8 can still be read as raw bytes.
    List<int> bytes = [0xc0, 0x40]; // Invalid UTF-8
    file.writeAsBytesSync(bytes);
    expect(await file.readAsBytes(), bytes);
  }

  test_readAsBytes_doesNotExist() {
    expect(file.readAsBytes(), _throwsFileSystemException);
  }

  test_readAsBytes_exists() async {
    var s = 'contents';
    file.writeAsStringSync(s);
    expect(await file.readAsBytes(), utf8.encode(s));
  }

  test_readAsString_badUtf8() {
    file.writeAsBytesSync([0xc0, 0x40]); // Invalid UTF-8
    expect(file.readAsString(), _throwsFileSystemException);
  }

  test_readAsString_doesNotExist() {
    expect(file.readAsString(), _throwsFileSystemException);
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

  test_writeAsBytesSync_directory() async {
    file.createDirectory();
    expect(() => file.writeAsBytesSync([0]), _throwsFileSystemException);
  }

  test_writeAsBytesSync_modifyAfterRead() async {
    // For efficiency we do not make defensive copies.
    file.writeAsBytesSync([1]);
    (await file.readAsBytes())[0] = 2;
    expect(await file.readAsBytes(), [2]);
  }

  test_writeAsBytesSync_modifyAfterWrite_Uint8List() async {
    // For efficiency we do not make defensive copies.
    var bytes = new Uint8List.fromList([1]);
    file.writeAsBytesSync(bytes);
    bytes[0] = 2;
    expect(await file.readAsBytes(), [2]);
  }

  test_writeAsBytesSync_modifyAfterWrite() async {
    // For efficiency we generally do not make defensive copies, but on the
    // other hrand we keep everything as `Uint8List`s internally, so in this
    // case a copy is actually made.
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

  test_writeAsStringSync_directory() async {
    file.createDirectory();
    expect(() => file.writeAsStringSync(''), _throwsFileSystemException);
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

abstract class MemoryFileSystemTestMixin implements _BaseTest {
  Uri tempUri;

  setUp() {
    _baseSetUp();
    tempUri = context.toUri(tempPath);
  }

  test_currentDirectory_trailingSlash() {
    // The currentDirectory should already end in a trailing slash.
    expect(fileSystem.currentDirectory.path, endsWith('/'));
    // A trailing slash should automatically be appended when creating a
    // MemoryFileSystem.
    var path = fileSystem.currentDirectory.path;
    var currentDirectoryWithoutSlash = fileSystem.currentDirectory
        .replace(path: path.substring(0, path.length - 1));
    expect(new MemoryFileSystem(currentDirectoryWithoutSlash).currentDirectory,
        fileSystem.currentDirectory);
    // If the currentDirectory supplied to the MemoryFileSystem constructor
    // already has a trailing slash, no further trailing slash should be added.
    expect(new MemoryFileSystem(fileSystem.currentDirectory).currentDirectory,
        fileSystem.currentDirectory);
  }

  test_entityForPath_absolutize() {
    expect(entityForPath('file.txt').uri,
        fileSystem.currentDirectory.resolve('file.txt'));
  }

  test_entityForPath_normalize_dot() {
    expect(entityForPath(join(tempPath, '.', 'file.txt')).uri,
        Uri.parse('$tempUri/file.txt'));
  }

  test_entityForPath_normalize_dotDot() {
    expect(entityForPath(join(tempPath, 'foo', '..', 'file.txt')).uri,
        Uri.parse('$tempUri/file.txt'));
  }

  test_entityForUri() {
    expect(fileSystem.entityForUri(Uri.parse('$tempUri/file.txt')).uri,
        Uri.parse('$tempUri/file.txt'));
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
            throwsA(const TypeMatcher<Error>()));
      }
    }
  }

  test_entityForUri_nonFileUri() {
    var uri = Uri.parse('package:foo/bar.dart');
    expect(fileSystem.entityForUri(uri).uri, uri);
  }

  test_entityForUri_normalize_dot() {
    expect(fileSystem.entityForUri(Uri.parse('$tempUri/./file.txt')).uri,
        Uri.parse('$tempUri/file.txt'));
  }

  test_entityForUri_normalize_dotDot() {
    expect(fileSystem.entityForUri(Uri.parse('$tempUri/foo/../file.txt')).uri,
        Uri.parse('$tempUri/file.txt'));
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
  pathos.Context get context;
  MemoryFileSystem get fileSystem;

  String get tempPath;

  MemoryFileSystemEntity entityForPath(String path) =>
      fileSystem.entityForUri(context.toUri(path));

  String join(String path1, String path2, [String path3, String path4]);

  void _baseSetUp();
}

class _BaseTestNative extends _BaseTest {
  final pathos.Context context = pathos.context;
  MemoryFileSystem fileSystem;
  String tempPath;

  String join(String path1, String path2, [String path3, String path4]) =>
      pathos.join(path1, path2, path3, path4);

  _baseSetUp() {
    tempPath = pathos.join(io.Directory.systemTemp.path, 'test_file_system');
    fileSystem = new MemoryFileSystem(pathos.toUri(io.Directory.current.path));
  }
}

class _BaseTestPosix extends _BaseTest {
  final pathos.Context context = pathos.posix;
  MemoryFileSystem fileSystem;
  String tempPath;

  String join(String path1, String path2, [String path3, String path4]) =>
      pathos.posix.join(path1, path2, path3, path4);

  void _baseSetUp() {
    tempPath = '/test_file_system';
    fileSystem = new MemoryFileSystem(Uri.parse('file:///cwd'));
  }
}

class _BaseTestWindows extends _BaseTest {
  final pathos.Context context = pathos.windows;
  MemoryFileSystem fileSystem;
  String tempPath;

  String join(String path1, String path2, [String path3, String path4]) =>
      pathos.windows.join(path1, path2, path3, path4);

  void _baseSetUp() {
    tempPath = r'c:\test_file_system';
    fileSystem = new MemoryFileSystem(Uri.parse('file:///c:/cwd'));
  }
}
