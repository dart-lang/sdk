// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'file_system_test_support.dart';

main() {
  if (!bool.fromEnvironment('skipPhysicalResourceProviderTests')) {
    defineReflectiveSuite(() {
      defineReflectiveTests(PhysicalFileTest);
      defineReflectiveTests(PhysicalFolderTest);
      defineReflectiveTests(PhysicalResourceProviderTest);
    });
  }
}

abstract class BaseTest extends FileSystemTestSupport {
  /// The resource provider to be used by the tests. Tests should use [provider]
  /// to access the resource provider.
  PhysicalResourceProvider _provider;

  /// A temporary directory on disk. All files and folders created by the tests
  /// should be inside this directory.
  /*late*/ io.Directory tempDirectory;

  /// The absolute path to the [tempDirectory]. This path will contain a
  /// symbolic link on some operating systems.
  @override
  /*late*/ String tempPath;

  /// A path to a folder within the [tempDirectory] that can be used by tests.
  @override
  /*late*/ String defaultFolderPath;

  /// A path to a file within the [defaultFolderPath] that can be used by tests.
  @override
  /*late*/ String defaultFilePath;

  /// The content used for the file at the [defaultFilePath] if it is created
  /// and no other content is provided.
  @override
  String get defaultFileContent => 'a';

  /// Return the resource provider to be used by the tests.
  @override
  PhysicalResourceProvider get provider => _provider ??= createProvider();

  /// Create the resource provider to be used by the tests. Subclasses can
  /// override this method to change the class of resource provider that is
  /// used.
  PhysicalResourceProvider createProvider() => PhysicalResourceProvider();

  @override
  File getFile({@required bool exists, String content, String filePath}) {
    File file = provider.getFile(filePath ?? defaultFilePath);
    if (exists) {
      file.parent.create();
      file.writeAsStringSync(content ?? defaultFileContent);
    }
    return file;
  }

  @override
  Folder getFolder({@required bool exists, String folderPath}) {
    Folder folder = provider.getFolder(folderPath ?? defaultFolderPath);
    if (exists) {
      folder.create();
    }
    return folder;
  }

  setUp() {
    tempDirectory = io.Directory.systemTemp.createTempSync('test_resource');
    //
    // On some platforms the path to the temp directory includes a symbolic
    // link. We remove that so that only the tests designed to test the behavior
    // of symbolic links will do so.
    //
    tempPath = tempDirectory.absolute.resolveSymbolicLinksSync();
    defaultFolderPath = join(tempPath, 'bar');
    defaultFilePath = join(tempPath, 'bar', 'test.dart');
  }

  tearDown() {
    tempDirectory.deleteSync(recursive: true);
  }
}

@reflectiveTest
class PhysicalFileTest extends BaseTest with FileTestMixin {
  @override
  test_delete_notExisting() {
    File file = getFile(exists: false);
    expect(file.exists, isFalse);

    expect(() => file.delete(), throwsA(isFileSystemException));
  }

  test_exists_invalidPath() {
    Folder folder = getFolder(exists: false);
    File file = folder.getChildAssumingFile(r'\l\package:o\other.dart');

    expect(file.exists, isFalse);
  }

  @override
  test_renameSync_notExisting() {
    String oldPath = join(tempPath, 'file.txt');
    String newPath = join(tempPath, 'new-file.txt');
    File oldFile = getFile(exists: false, filePath: oldPath);

    expect(() => oldFile.renameSync(newPath), throwsA(isFileSystemException));
  }

  @override
  test_resolveSymbolicLinksSync_links_existing() {
    String pathA = join(tempPath, defaultFileContent);
    String pathB = join(pathA, 'b');
    io.Directory(pathB).createSync(recursive: true);
    String filePath = join(pathB, 'test.txt');
    io.File testFile = io.File(filePath);
    testFile.writeAsStringSync('test');

    String pathC = join(tempPath, 'c');
    String pathD = join(pathC, 'd');
    io.Link(pathD).createSync(pathA, recursive: true);

    String pathE = join(tempPath, 'e');
    String pathF = join(pathE, 'f');
    io.Link(pathF).createSync(pathC, recursive: true);

    String linkPath = join(tempPath, 'e', 'f', 'd', 'b', 'test.txt');
    File file = provider.getFile(linkPath);

    expect(file.resolveSymbolicLinksSync().path,
        testFile.resolveSymbolicLinksSync());
  }

  @override
  test_resolveSymbolicLinksSync_links_notExisting() {
    var a = join(tempPath, 'a.dart');
    var b = join(tempPath, 'b.dart');

    io.Link(b).createSync(a, recursive: true);

    expect(() {
      provider.getFile(b).resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  @override
  test_resolveSymbolicLinksSync_noLinks_notExisting() {
    File file = getFile(exists: false);

    expect(() {
      file.resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  @override
  test_writeAsBytesSync_notExisting() {
    File file = getFile(exists: false);

    expect(() => file.writeAsBytesSync(<int>[99, 99]),
        throwsA(isFileSystemException));
  }

  @override
  test_writeAsStringSync_notExisting() {
    File file = getFile(exists: false);

    expect(() => file.writeAsStringSync('cc'), throwsA(isFileSystemException));
  }
}

@reflectiveTest
class PhysicalFolderTest extends BaseTest with FolderTestMixin {}

@reflectiveTest
class PhysicalResourceProviderTest extends BaseTest
    with ResourceProviderTestMixin {}
