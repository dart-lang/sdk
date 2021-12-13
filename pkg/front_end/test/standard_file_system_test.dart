// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

library front_end.test.standard_file_system_test;

import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' show Random;

import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StandardFileSystemTest);
    defineReflectiveTests(FileTest);
    defineReflectiveTests(DirectoryTest);
    defineReflectiveTests(DataTest);
  });
}

final Matcher _throwsFileSystemException =
    throwsA(const TypeMatcher<FileSystemException>());

@reflectiveTest
class DirectoryTest extends _BaseTest {
  late String path;
  late FileSystemEntity dir;

  @override
  void setUp() {
    super.setUp();
    path = p.join(tempPath, 'dir');
    dir = StandardFileSystem.instance.entityForUri(p.toUri(path));
  }

  void test_equals_differentPaths() {
    expect(dir == entityForPath(p.join(tempPath, 'dir2')), isFalse);
  }

  void test_equals_samePath() {
    expect(dir == entityForPath(p.join(tempPath, 'dir')), isTrue);
  }

  Future<void> test_exists_directoryExists() async {
    await new io.Directory(path).create();
    expect(await dir.exists(), isTrue);
  }

  Future<void> test_exists_doesNotExist() async {
    expect(await dir.exists(), isFalse);
  }

  Future<void> test_readAsBytes() async {
    await new io.Directory(path).create();
    await expectLater(dir.readAsBytes, _throwsFileSystemException);
  }

  void test_uri() {
    expect(dir.uri, p.toUri(path));
  }
}

@reflectiveTest
class FileTest extends _BaseTest {
  late String path;
  late FileSystemEntity file;

  @override
  void setUp() {
    super.setUp();
    path = p.join(tempPath, 'file.txt');
    file = StandardFileSystem.instance.entityForUri(p.toUri(path));
  }

  void test_equals_differentPaths() {
    expect(file == entityForPath(p.join(tempPath, 'file2.txt')), isFalse);
  }

  void test_equals_samePath() {
    expect(file == entityForPath(p.join(tempPath, 'file.txt')), isTrue);
  }

  Future<void> test_exists_doesNotExist() async {
    expect(await file.exists(), isFalse);
  }

  Future<void> test_exists_fileExists() async {
    new io.File(path).writeAsStringSync('contents');
    expect(await file.exists(), isTrue);
  }

  void test_hashCode_samePath() {
    expect(file.hashCode, entityForPath(p.join(tempPath, 'file.txt')).hashCode);
  }

  Future<void> test_readAsBytes_badUtf8() async {
    // A file containing invalid UTF-8 can still be read as raw bytes.
    List<int> bytes = [0xc0, 0x40]; // Invalid UTF-8
    new io.File(path).writeAsBytesSync(bytes);
    expect(await file.readAsBytes(), bytes);
  }

  Future<void> test_readAsBytes_doesNotExist() async {
    await expectLater(file.readAsBytes, _throwsFileSystemException);
  }

  Future<void> test_readAsBytes_exists() async {
    var s = 'contents';
    new io.File(path).writeAsStringSync(s);
    expect(await file.readAsBytes(), utf8.encode(s));
  }

  Future<void> test_readAsString_badUtf8() async {
    new io.File(path).writeAsBytesSync([0xc0, 0x40]); // Invalid UTF-8
    await expectLater(file.readAsString, _throwsFileSystemException);
  }

  Future<void> test_readAsString_doesNotExist() async {
    await expectLater(file.readAsString, _throwsFileSystemException);
  }

  Future<void> test_readAsString_exists() async {
    var s = 'contents';
    new io.File(path).writeAsStringSync(s);
    expect(await file.readAsString(), s);
  }

  Future<void> test_readAsString_utf8() async {
    var bytes = [0xe2, 0x82, 0xac]; // Unicode € symbol (in UTF-8)
    new io.File(path).writeAsBytesSync(bytes);
    expect(await file.readAsString(), '\u20ac');
  }

  void test_uri() {
    expect(file.uri, p.toUri(path));
  }
}

@reflectiveTest
class StandardFileSystemTest extends _BaseTest {
  late Uri tempUri;

  @override
  void setUp() {
    super.setUp();
    tempUri = new Uri.directory(tempPath);
  }

  void test_entityForPath() {
    var path = p.join(tempPath, 'file.txt');
    expect(entityForPath(path).uri, p.toUri(path));
  }

  void test_entityForPath_absolutize() {
    expect(entityForPath('file.txt').uri,
        p.toUri(new io.File('file.txt').absolute.path));
  }

  void test_entityForPath_normalize_dot() {
    expect(entityForPath(p.join(tempPath, '.', 'file.txt')).uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }

  void test_entityForPath_normalize_dotDot() {
    expect(entityForPath(p.join(tempPath, 'foo', '..', 'file.txt')).uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }

  void test_entityForUri() {
    expect(
        StandardFileSystem.instance
            .entityForUri(Uri.parse('${tempUri}file.txt'))
            .uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }

  void test_entityForUri_bareUri_absolute() {
    expect(StandardFileSystem.instance.entityForUri(Uri.parse('/file.txt')).uri,
        Uri.parse('file:///file.txt'));
  }

  void test_entityForUri_fileUri_relative() {
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
        expect(() => StandardFileSystem.instance.entityForUri(uri),
            throwsA(const TypeMatcher<Error>()));
      }
    }
  }

  Future<void> test_entityForUri_nonFileUri() async {
    await expectLater(
        () => StandardFileSystem.instance
            .entityForUri(Uri.parse('package:foo/bar.dart')),
        _throwsFileSystemException);
  }

  void test_entityForUri_normalize_dot() {
    expect(
        StandardFileSystem.instance
            .entityForUri(Uri.parse('${tempUri}./file.txt'))
            .uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }

  void test_entityForUri_normalize_dotDot() {
    expect(
        StandardFileSystem.instance
            .entityForUri(Uri.parse('${tempUri}foo/../file.txt'))
            .uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }
}

class _BaseTest {
  late io.Directory tempDirectory;
  late String tempPath;

  FileSystemEntity entityForPath(String path) =>
      StandardFileSystem.instance.entityForUri(p.toUri(path));

  void setUp() {
    tempDirectory = io.Directory.systemTemp.createTempSync('test_file_system');
    tempPath = tempDirectory.absolute.path;
  }

  Future<void> tearDown() async {
    try {
      tempDirectory.deleteSync(recursive: true);
    } on io.FileSystemException {
      // Sometimes on Windows the delete fails with errno 32
      // (ERROR_SHARING_VIOLATION: The process cannot access the file because it
      // is being used by another process).  Wait 1 second and try again.
      await new Future.delayed(new Duration(seconds: 1));
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

@reflectiveTest
class DataTest {
  Future<void> test_Data_URIs() async {
    String string = "<{[DART]}>";
    Uri string_uri = new Uri.dataFromString(string, base64: false);
    Uri string_uri_base64 = new Uri.dataFromString(string, base64: true);

    Random random = new Random(123);
    List<int> bytes = new List.generate(1000, (index) => random.nextInt(256));
    Uri bytes_uri = new Uri.dataFromBytes(bytes, percentEncoded: true);
    Uri bytes_uri_base64 = new Uri.dataFromBytes(bytes, percentEncoded: false);

    StandardFileSystem fs = StandardFileSystem.instance;
    expect(string, await fs.entityForUri(string_uri).readAsString());
    expect(string, await fs.entityForUri(string_uri_base64).readAsString());
    expect(bytes, await fs.entityForUri(bytes_uri).readAsBytes());
    expect(bytes, await fs.entityForUri(bytes_uri_base64).readAsBytes());
  }
}
