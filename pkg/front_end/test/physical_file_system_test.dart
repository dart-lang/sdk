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
  });
}

@reflectiveTest
class FileTest extends _BaseTest {
  String path;
  FileSystemEntity file;

  setUp() {
    super.setUp();
    path = p.join(tempPath, 'file.txt');
    file = PhysicalFileSystem.instance.entityForPath(path);
  }

  test_equals_differentPaths() {
    expect(
        file ==
            PhysicalFileSystem.instance
                .entityForPath(p.join(tempPath, 'file2.txt')),
        isFalse);
  }

  test_equals_samePath() {
    expect(
        file ==
            PhysicalFileSystem.instance
                .entityForPath(p.join(tempPath, 'file.txt')),
        isTrue);
  }

  test_hashCode_samePath() {
    expect(
        file.hashCode,
        PhysicalFileSystem.instance
            .entityForPath(p.join(tempPath, 'file.txt'))
            .hashCode);
  }

  test_path() {
    expect(file.path, path);
  }

  test_readAsBytes_badUtf8() async {
    // A file containing invalid UTF-8 can still be read as raw bytes.
    List<int> bytes = [0xc0, 0x40]; // Invalid UTF-8
    new io.File(path).writeAsBytesSync(bytes);
    expect(await file.readAsBytes(), bytes);
  }

  test_readAsBytes_doesNotExist() {
    expect(file.readAsBytes(), throwsException);
  }

  test_readAsBytes_exists() async {
    var s = 'contents';
    new io.File(path).writeAsStringSync(s);
    expect(await file.readAsBytes(), UTF8.encode(s));
  }

  test_readAsString_badUtf8() {
    new io.File(path).writeAsBytesSync([0xc0, 0x40]); // Invalid UTF-8
    expect(file.readAsString(), throwsException);
  }

  test_readAsString_doesNotExist() {
    expect(file.readAsString(), throwsException);
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
    expect(PhysicalFileSystem.instance.entityForPath(path).path, path);
  }

  test_entityForPath_absolutize() {
    expect(PhysicalFileSystem.instance.entityForPath('file.txt').path,
        new io.File('file.txt').absolute.path);
  }

  test_entityForPath_normalize_dot() {
    expect(
        PhysicalFileSystem.instance
            .entityForPath(p.join(tempPath, '.', 'file.txt'))
            .path,
        p.join(tempPath, 'file.txt'));
  }

  test_entityForPath_normalize_dotDot() {
    expect(
        PhysicalFileSystem.instance
            .entityForPath(p.join(tempPath, 'foo', '..', 'file.txt'))
            .path,
        p.join(tempPath, 'file.txt'));
  }

  test_entityForUri() {
    expect(
        PhysicalFileSystem.instance
            .entityForUri(Uri.parse('$tempUri/file.txt'))
            .path,
        p.join(tempPath, 'file.txt'));
  }

  test_entityForUri_bareUri_absolute() {
    expect(
        () => PhysicalFileSystem.instance.entityForUri(Uri.parse('/file.txt')),
        throwsA(new isInstanceOf<Error>()));
  }

  test_entityForUri_bareUri_relative() {
    expect(
        () => PhysicalFileSystem.instance.entityForUri(Uri.parse('file.txt')),
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
        expect(() => PhysicalFileSystem.instance.entityForUri(uri),
            throwsA(new isInstanceOf<Error>()));
      }
    }
  }

  test_entityForUri_nonFileUri() {
    expect(
        () => PhysicalFileSystem.instance
            .entityForUri(Uri.parse('package:foo/bar.dart')),
        throwsA(new isInstanceOf<Error>()));
  }

  test_entityForUri_normalize_dot() {
    expect(
        PhysicalFileSystem.instance
            .entityForUri(Uri.parse('$tempUri/./file.txt'))
            .path,
        p.join(tempPath, 'file.txt'));
  }

  test_entityForUri_normalize_dotDot() {
    expect(
        PhysicalFileSystem.instance
            .entityForUri(Uri.parse('$tempUri/foo/../file.txt'))
            .path,
        p.join(tempPath, 'file.txt'));
  }
}

class _BaseTest {
  io.Directory tempDirectory;
  String tempPath;

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
