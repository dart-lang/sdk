// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

library front_end.test.physical_file_system_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:front_end/file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PhysicalFileSystemTest);
    defineReflectiveTests(FileTest);
    defineReflectiveTests(DirectoryTest);
  });
}

const Matcher _throwsFileSystemException =
    const Throws(const isInstanceOf<FileSystemException>());

@reflectiveTest
class DirectoryTest extends _BaseTest {
  String path;
  FileSystemEntity dir;

  setUp() {
    super.setUp();
    path = p.join(tempPath, 'dir');
    dir = PhysicalFileSystem.instance.entityForUri(p.toUri(path));
  }

  test_equals_differentPaths() {
    expect(dir == entityForPath(p.join(tempPath, 'dir2')), isFalse);
  }

  test_equals_samePath() {
    expect(dir == entityForPath(p.join(tempPath, 'dir')), isTrue);
  }

  test_exists_directoryExists() async {
    await new io.Directory(path).create();
    expect(await dir.exists(), isTrue);
  }

  test_exists_doesNotExist() async {
    expect(await dir.exists(), isFalse);
  }

  test_readAsBytes() async {
    await new io.Directory(path).create();
    expect(dir.readAsBytes(), _throwsFileSystemException);
  }

  test_uri() {
    expect(dir.uri, p.toUri(path));
  }
}

@reflectiveTest
class FileTest extends _BaseTest {
  String path;
  FileSystemEntity file;

  setUp() {
    super.setUp();
    path = p.join(tempPath, 'file.txt');
    file = PhysicalFileSystem.instance.entityForUri(p.toUri(path));
  }

  test_equals_differentPaths() {
    expect(file == entityForPath(p.join(tempPath, 'file2.txt')), isFalse);
  }

  test_equals_samePath() {
    expect(file == entityForPath(p.join(tempPath, 'file.txt')), isTrue);
  }

  test_exists_doesNotExist() async {
    expect(await file.exists(), isFalse);
  }

  test_exists_fileExists() async {
    new io.File(path).writeAsStringSync('contents');
    expect(await file.exists(), isTrue);
  }

  test_hashCode_samePath() {
    expect(file.hashCode, entityForPath(p.join(tempPath, 'file.txt')).hashCode);
  }

  test_readAsBytes_badUtf8() async {
    // A file containing invalid UTF-8 can still be read as raw bytes.
    List<int> bytes = [0xc0, 0x40]; // Invalid UTF-8
    new io.File(path).writeAsBytesSync(bytes);
    expect(await file.readAsBytes(), bytes);
  }

  test_readAsBytes_doesNotExist() {
    expect(file.readAsBytes(), _throwsFileSystemException);
  }

  test_readAsBytes_exists() async {
    var s = 'contents';
    new io.File(path).writeAsStringSync(s);
    expect(await file.readAsBytes(), UTF8.encode(s));
  }

  test_readAsString_badUtf8() {
    new io.File(path).writeAsBytesSync([0xc0, 0x40]); // Invalid UTF-8
    expect(file.readAsString(), _throwsFileSystemException);
  }

  test_readAsString_doesNotExist() {
    expect(file.readAsString(), _throwsFileSystemException);
  }

  test_readAsString_exists() async {
    var s = 'contents';
    new io.File(path).writeAsStringSync(s);
    expect(await file.readAsString(), s);
  }

  test_readAsString_utf8() async {
    var bytes = [0xe2, 0x82, 0xac]; // Unicode € symbol (in UTF-8)
    new io.File(path).writeAsBytesSync(bytes);
    expect(await file.readAsString(), '\u20ac');
  }

  test_uri() {
    expect(file.uri, p.toUri(path));
  }
}

@reflectiveTest
class PhysicalFileSystemTest extends _BaseTest {
  Uri tempUri;

  setUp() {
    super.setUp();
    tempUri = new Uri.directory(tempPath);
  }

  test_entityForPath() {
    var path = p.join(tempPath, 'file.txt');
    expect(entityForPath(path).uri, p.toUri(path));
  }

  test_entityForPath_absolutize() {
    expect(entityForPath('file.txt').uri,
        p.toUri(new io.File('file.txt').absolute.path));
  }

  test_entityForPath_normalize_dot() {
    expect(entityForPath(p.join(tempPath, '.', 'file.txt')).uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }

  test_entityForPath_normalize_dotDot() {
    expect(entityForPath(p.join(tempPath, 'foo', '..', 'file.txt')).uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }

  test_entityForUri() {
    expect(
        PhysicalFileSystem.instance
            .entityForUri(Uri.parse('${tempUri}file.txt'))
            .uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }

  test_entityForUri_bareUri_absolute() {
    expect(PhysicalFileSystem.instance.entityForUri(Uri.parse('/file.txt')).uri,
        Uri.parse('file:///file.txt'));
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
        expect(() => PhysicalFileSystem.instance.entityForUri(uri),
            throwsA(new isInstanceOf<Error>()));
      }
    }
  }

  test_entityForUri_nonFileUri() {
    expect(
        () => PhysicalFileSystem.instance
            .entityForUri(Uri.parse('package:foo/bar.dart')),
        _throwsFileSystemException);
  }

  test_entityForUri_normalize_dot() {
    expect(
        PhysicalFileSystem.instance
            .entityForUri(Uri.parse('${tempUri}./file.txt'))
            .uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }

  test_entityForUri_normalize_dotDot() {
    expect(
        PhysicalFileSystem.instance
            .entityForUri(Uri.parse('${tempUri}foo/../file.txt'))
            .uri,
        p.toUri(p.join(tempPath, 'file.txt')));
  }
}

class _BaseTest {
  io.Directory tempDirectory;
  String tempPath;

  FileSystemEntity entityForPath(String path) =>
      PhysicalFileSystem.instance.entityForUri(p.toUri(path));

  setUp() {
    tempDirectory = io.Directory.systemTemp.createTempSync('test_file_system');
    tempPath = tempDirectory.absolute.path;
  }

  tearDown() async {
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
