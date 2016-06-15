// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.file_system.memory_file_system_test;

import 'dart:async';
import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';
import 'package:watcher/watcher.dart';

import '../reflective_tests.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(FileSystemExceptionTest);
  runReflectiveTests(FileTest);
  runReflectiveTests(FolderTest);
  runReflectiveTests(MemoryFileSourceExistingTest);
  runReflectiveTests(MemoryFileSourceNotExistingTest);
  runReflectiveTests(MemoryResourceProviderTest);
}

var _isFile = new isInstanceOf<File>();
var _isFileSystemException = new isInstanceOf<FileSystemException>();
var _isFolder = new isInstanceOf<Folder>();

@reflectiveTest
class FileSystemExceptionTest {
  void test_constructor() {
    var exception = new FileSystemException('/my/path', 'my message');
    expect(exception.path, '/my/path');
    expect(exception.message, 'my message');
    expect(exception.toString(),
        'FileSystemException(path=/my/path; message=my message)');
  }
}

@reflectiveTest
class FileTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();

  void test_delete() {
    File file = provider.newFile('/foo/file.txt', 'content');
    expect(file.exists, isTrue);
    // delete
    file.delete();
    expect(file.exists, isFalse);
  }

  void test_equals_beforeAndAfterCreate() {
    String path = '/file.txt';
    File file1 = provider.getResource(path);
    provider.newFile(path, 'contents');
    File file2 = provider.getResource(path);
    expect(file1 == file2, isTrue);
  }

  void test_equals_false() {
    File fileA = provider.getResource('/fileA.txt');
    File fileB = provider.getResource('/fileB.txt');
    expect(fileA == new Object(), isFalse);
    expect(fileA == fileB, isFalse);
  }

  void test_equals_true() {
    File file = provider.getResource('/file.txt');
    expect(file == file, isTrue);
  }

  void test_exists_false() {
    File file = provider.getResource('/file.txt');
    expect(file, isNotNull);
    expect(file.exists, isFalse);
  }

  void test_exists_true() {
    provider.newFile('/foo/file.txt', 'qwerty');
    File file = provider.getResource('/foo/file.txt');
    expect(file, isNotNull);
    expect(file.exists, isTrue);
  }

  void test_fullName() {
    File file = provider.getResource('/foo/bar/file.txt');
    expect(file.path, '/foo/bar/file.txt');
  }

  void test_hashCode() {
    String path = '/foo/bar/file.txt';
    File file1 = provider.getResource(path);
    provider.newFile(path, 'contents');
    File file2 = provider.getResource(path);
    expect(file1.hashCode, equals(file2.hashCode));
  }

  void test_isOrContains() {
    String path = '/foo/bar/file.txt';
    File file = provider.getResource(path);
    expect(file.isOrContains(path), isTrue);
    expect(file.isOrContains('/foo/bar'), isFalse);
  }

  void test_modificationStamp_doesNotExist() {
    String path = '/foo/bar/file.txt';
    File file = provider.newFile(path, 'qwerty');
    provider.deleteFile(path);
    expect(() {
      file.modificationStamp;
    }, throwsA(_isFileSystemException));
  }

  void test_modificationStamp_exists() {
    String path = '/foo/bar/file.txt';
    File file = provider.newFile(path, 'qwerty');
    expect(file.modificationStamp, isNonNegative);
  }

  void test_parent() {
    provider.newFile('/foo/bar/file.txt', 'content');
    File file = provider.getResource('/foo/bar/file.txt');
    Resource parent = file.parent;
    expect(parent, new isInstanceOf<Folder>());
    expect(parent.path, equals('/foo/bar'));
  }

  void test_readAsBytesSync_doesNotExist() {
    File file = provider.getResource('/test.bin');
    expect(() {
      file.readAsBytesSync();
    }, throwsA(_isFileSystemException));
  }

  void test_readAsBytesSync_exists() {
    List<int> bytes = <int>[1, 2, 3, 4, 5];
    File file = provider.newFileWithBytes('/file.bin', bytes);
    expect(file.readAsBytesSync(), bytes);
  }

  void test_readAsStringSync_doesNotExist() {
    File file = provider.getResource('/test.txt');
    expect(() {
      file.readAsStringSync();
    }, throwsA(_isFileSystemException));
  }

  void test_readAsStringSync_exists() {
    File file = provider.newFile('/file.txt', 'abc');
    expect(file.readAsStringSync(), 'abc');
  }

  void test_renameSync_newDoesNotExist() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = '/foo/bar/new-file.txt';
    File file = provider.newFile(oldPath, 'text');
    File newFile = file.renameSync(newPath);
    expect(file.path, oldPath);
    expect(file.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'text');
  }

  void test_renameSync_newExists_file() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = '/foo/bar/new-file.txt';
    File file = provider.newFile(oldPath, 'text');
    provider.newFile(newPath, 'new text');
    File newFile = file.renameSync(newPath);
    expect(file.path, oldPath);
    expect(file.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'text');
  }

  void test_renameSync_newExists_folder() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = '/foo/bar/baz';
    File file = provider.newFile(oldPath, 'text');
    provider.newFolder(newPath);
    expect(() {
      file.renameSync(newPath);
    }, throwsA(_isFileSystemException));
    expect(file.path, oldPath);
    expect(file.exists, isTrue);
  }

  void test_shortName() {
    File file = provider.getResource('/foo/bar/file.txt');
    expect(file.shortName, 'file.txt');
  }

  void test_toString() {
    File file = provider.getResource('/foo/bar/file.txt');
    expect(file.toString(), '/foo/bar/file.txt');
  }

  void test_writeAsBytesSync_existing() {
    File file = provider.newFileWithBytes('/foo/file.bin', <int>[1, 2]);
    expect(file.readAsBytesSync(), <int>[1, 2]);
    // write new bytes
    file.writeAsBytesSync(<int>[10, 20]);
    expect(file.readAsBytesSync(), <int>[10, 20]);
  }

  void test_writeAsBytesSync_new() {
    File file = provider.getFile('/foo/file.bin');
    expect(file.exists, false);
    // write new bytes
    file.writeAsBytesSync(<int>[10, 20]);
    expect(file.exists, true);
    expect(file.readAsBytesSync(), <int>[10, 20]);
  }
}

@reflectiveTest
class FolderTest {
  static const String path = '/foo/bar';

  MemoryResourceProvider provider = new MemoryResourceProvider();
  Folder folder;

  void setUp() {
    folder = provider.newFolder(path);
  }

  void test_canonicalizePath() {
    expect(folder.canonicalizePath('baz'), equals('/foo/bar/baz'));
    expect(folder.canonicalizePath('/baz'), equals('/baz'));
    expect(folder.canonicalizePath('../baz'), equals('/foo/baz'));
    expect(folder.canonicalizePath('/a/b/../c'), equals('/a/c'));
    expect(folder.canonicalizePath('./baz'), equals('/foo/bar/baz'));
    expect(folder.canonicalizePath('/a/b/./c'), equals('/a/b/c'));
  }

  void test_contains() {
    expect(folder.contains('/foo/bar/aaa.txt'), isTrue);
    expect(folder.contains('/foo/bar/aaa/bbb.txt'), isTrue);
    expect(folder.contains('/baz.txt'), isFalse);
    expect(folder.contains('/foo/bar'), isFalse);
  }

  void test_delete() {
    Folder folder = provider.newFolder('/foo');
    Folder barFolder = provider.newFolder('/foo/bar');
    File aFile = provider.newFile('/foo/bar/a.txt', '');
    File bFile = provider.newFile('/foo/b.txt', '');
    expect(folder.exists, isTrue);
    expect(barFolder.exists, isTrue);
    expect(aFile.exists, isTrue);
    expect(bFile.exists, isTrue);
    // delete 'folder'
    folder.delete();
    expect(folder.exists, isFalse);
    expect(barFolder.exists, isFalse);
    expect(aFile.exists, isFalse);
    expect(bFile.exists, isFalse);
  }

  void test_equal_false() {
    String path2 = '/foo/baz';
    Folder folder2 = provider.newFolder(path2);
    expect(folder == folder2, isFalse);
  }

  void test_equal_true() {
    Folder folder2 = provider.getResource(path);
    expect(folder == folder2, isTrue);
  }

  void test_getChild_doesNotExist() {
    File file = folder.getChild('file.txt');
    expect(file, isNotNull);
    expect(file.exists, isFalse);
  }

  void test_getChild_file() {
    provider.newFile('/foo/bar/file.txt', 'content');
    File child = folder.getChild('file.txt');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  void test_getChild_folder() {
    provider.newFolder('/foo/bar/baz');
    Folder child = folder.getChild('baz');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  void test_getChildAssumingFile_doesNotExist() {
    File child = folder.getChildAssumingFile('name');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFile_file() {
    provider.newFile('/foo/bar/name', 'content');
    File child = folder.getChildAssumingFile('name');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  void test_getChildAssumingFile_folder() {
    provider.newFolder('/foo/bar/name');
    File child = folder.getChildAssumingFile('name');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFolder_doesNotExist() {
    Folder child = folder.getChildAssumingFolder('foldername');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFolder_file() {
    provider.newFile('/foo/bar/foldername', 'content');
    Folder child = folder.getChildAssumingFolder('foldername');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFolder_folder() {
    provider.newFolder('/foo/bar/foldername');
    Folder child = folder.getChildAssumingFolder('foldername');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  void test_getChildren_doesNotExist() {
    folder = folder.getChildAssumingFolder('no-such-folder');
    expect(() {
      folder.getChildren();
    }, throwsA(_isFileSystemException));
  }

  void test_getChildren_exists() {
    provider.newFile('/foo/bar/a.txt', 'aaa');
    provider.newFolder('/foo/bar/bFolder');
    provider.newFile('/foo/bar/c.txt', 'ccc');
    // prepare 3 children
    List<Resource> children = folder.getChildren();
    expect(children, hasLength(3));
    children.sort((a, b) => a.shortName.compareTo(b.shortName));
    // check that each child exists
    children.forEach((child) {
      expect(child.exists, true);
    });
    // check names
    expect(children[0].shortName, 'a.txt');
    expect(children[1].shortName, 'bFolder');
    expect(children[2].shortName, 'c.txt');
    // check types
    expect(children[0], _isFile);
    expect(children[1], _isFolder);
    expect(children[2], _isFile);
  }

  void test_hashCode() {
    Folder folder2 = provider.getResource(path);
    expect(folder.hashCode, folder2.hashCode);
  }

  void test_isOrContains() {
    expect(folder.isOrContains('/foo/bar'), isTrue);
    expect(folder.isOrContains('/foo/bar/aaa.txt'), isTrue);
    expect(folder.isOrContains('/foo/bar/aaa/bbb.txt'), isTrue);
    expect(folder.isOrContains('/baz.txt'), isFalse);
  }

  void test_parent() {
    Resource parent1 = folder.parent;
    expect(parent1, new isInstanceOf<Folder>());
    expect(parent1.path, equals('/foo'));
    Resource parent2 = parent1.parent;
    expect(parent2, new isInstanceOf<Folder>());
    expect(parent2.path, equals('/'));
    expect(parent2.parent, isNull);
  }
}

@reflectiveTest
class MemoryFileSourceExistingTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();
  Source source;

  setUp() {
    File file = provider.newFile('/foo/test.dart', 'library test;');
    source = file.createSource();
  }

  void test_contents() {
    TimestampedData<String> contents = source.contents;
    expect(contents.data, 'library test;');
  }

  void test_encoding() {
    expect(source.encoding, 'file:///foo/test.dart');
  }

  void test_equals_false_differentFile() {
    File fileA = provider.newFile('/foo/a.dart', '');
    File fileB = provider.newFile('/foo/b.dart', '');
    Source sourceA = fileA.createSource();
    Source sourceB = fileB.createSource();
    expect(sourceA == sourceB, isFalse);
  }

  void test_equals_false_notMemorySource() {
    File file = provider.newFile('/foo/test.dart', '');
    Source source = file.createSource();
    expect(source == new Object(), isFalse);
  }

  void test_equals_true_sameFile() {
    File file = provider.newFile('/foo/test.dart', '');
    Source sourceA = file.createSource();
    Source sourceB = file.createSource();
    expect(sourceA == sourceB, isTrue);
  }

  void test_equals_true_self() {
    File file = provider.newFile('/foo/test.dart', '');
    Source source = file.createSource();
    expect(source == source, isTrue);
  }

  void test_exists() {
    expect(source.exists(), isTrue);
  }

  void test_fullName() {
    expect(source.fullName, '/foo/test.dart');
  }

  void test_hashCode() {
    source.hashCode;
  }

  void test_resolveRelative() {
    Uri relative = resolveRelativeUri(source.uri, new Uri.file('bar/baz.dart'));
    expect(relative.path, '/foo/bar/baz.dart');
  }

  void test_resolveRelative_dart() {
    File file = provider.newFile('/sdk/lib/core/core.dart', '');
    Source source = file.createSource(Uri.parse('dart:core'));
    Uri resolved = resolveRelativeUri(source.uri, Uri.parse('int.dart'));
    expect(resolved.toString(), 'dart:core/int.dart');
  }

  void test_shortName() {
    expect(source.shortName, 'test.dart');
  }
}

@reflectiveTest
class MemoryFileSourceNotExistingTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();
  Source source;

  setUp() {
    File file = provider.getResource('/foo/test.dart');
    source = file.createSource();
  }

  void test_contents() {
    expect(() {
      source.contents;
    }, throwsA(_isFileSystemException));
  }

  void test_encoding() {
    expect(source.encoding, 'file:///foo/test.dart');
  }

  void test_exists() {
    expect(source.exists(), isFalse);
  }

  void test_fullName() {
    expect(source.fullName, '/foo/test.dart');
  }

  void test_modificationStamp() {
    expect(source.modificationStamp, -1);
  }

  void test_resolveRelative() {
    Uri relative = resolveRelativeUri(source.uri, new Uri.file('bar/baz.dart'));
    expect(relative.path, '/foo/bar/baz.dart');
  }

  void test_shortName() {
    expect(source.shortName, 'test.dart');
  }
}

@reflectiveTest
class MemoryResourceProviderTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();

  void test_deleteFile_folder() {
    String path = '/my/file';
    provider.newFolder(path);
    expect(() {
      provider.deleteFile(path);
    }, throwsA(new isInstanceOf<ArgumentError>()));
    expect(provider.getResource(path), new isInstanceOf<Folder>());
  }

  void test_deleteFile_notExistent() {
    String path = '/my/file';
    expect(() {
      provider.deleteFile(path);
    }, throwsA(new isInstanceOf<ArgumentError>()));
    Resource file = provider.getResource(path);
    expect(file, isNotNull);
    expect(file.exists, isFalse);
  }

  void test_deleteFile_success() {
    String path = '/my/file';
    provider.newFile(path, 'contents');
    Resource file = provider.getResource(path);
    expect(file, new isInstanceOf<File>());
    expect(file.exists, isTrue);
    provider.deleteFile(path);
    expect(file.exists, isFalse);
  }

  void test_getStateLocation_uniqueness() {
    String idOne = 'one';
    Folder folderOne = provider.getStateLocation(idOne);
    expect(folderOne, isNotNull);
    String idTwo = 'two';
    Folder folderTwo = provider.getStateLocation(idTwo);
    expect(folderTwo, isNotNull);
    expect(folderTwo, isNot(equals(folderOne)));
    expect(provider.getStateLocation(idOne), equals(folderOne));
  }

  void test_modifyFile_isFolder() {
    String path = '/my/file';
    provider.newFolder(path);
    expect(() {
      provider.modifyFile(path, 'contents');
    }, throwsA(new isInstanceOf<ArgumentError>()));
    expect(provider.getResource(path), new isInstanceOf<Folder>());
  }

  void test_modifyFile_notExistent() {
    String path = '/my/file';
    expect(() {
      provider.modifyFile(path, 'contents');
    }, throwsA(new isInstanceOf<ArgumentError>()));
    Resource file = provider.getResource(path);
    expect(file, isNotNull);
    expect(file.exists, isFalse);
  }

  void test_modifyFile_success() {
    String path = '/my/file';
    provider.newFile(path, 'contents 1');
    Resource file = provider.getResource(path);
    expect(file, new isInstanceOf<File>());
    Source source = (file as File).createSource();
    expect(source.contents.data, equals('contents 1'));
    provider.modifyFile(path, 'contents 2');
    expect(source.contents.data, equals('contents 2'));
  }

  void test_newFileWithBytes() {
    String path = '/my/file';
    List<int> bytes = <int>[1, 2, 3, 4, 5];
    provider.newFileWithBytes(path, bytes);
    File file = provider.getResource(path);
    expect(file, isNotNull);
    expect(file.exists, isTrue);
    expect(file.readAsBytesSync(), bytes);
  }

  void test_newFolder_alreadyExists_asFile() {
    provider.newFile('/my/file', 'qwerty');
    expect(() {
      provider.newFolder('/my/file');
    }, throwsA(new isInstanceOf<ArgumentError>()));
  }

  void test_newFolder_alreadyExists_asFolder() {
    Folder folder = provider.newFolder('/my/folder');
    Folder newFolder = provider.newFolder('/my/folder');
    expect(newFolder, folder);
  }

  void test_newFolder_emptyPath() {
    expect(() {
      provider.newFolder('');
    }, throwsA(new isInstanceOf<ArgumentError>()));
  }

  void test_newFolder_notAbsolute() {
    expect(() {
      provider.newFolder('not/absolute');
    }, throwsA(new isInstanceOf<ArgumentError>()));
  }

  test_watch_createFile() {
    String rootPath = '/my/path';
    provider.newFolder(rootPath);
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      String path = posix.join(rootPath, 'foo');
      provider.newFile(path, 'contents');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.ADD));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watch_deleteFile() {
    String rootPath = '/my/path';
    provider.newFolder(rootPath);
    String path = posix.join(rootPath, 'foo');
    provider.newFile(path, 'contents 1');
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      provider.deleteFile(path);
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.REMOVE));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watch_modifyFile() {
    String rootPath = '/my/path';
    provider.newFolder(rootPath);
    String path = posix.join(rootPath, 'foo');
    provider.newFile(path, 'contents 1');
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      provider.modifyFile(path, 'contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watch_modifyFile_inSubDir() {
    String rootPath = '/my/path';
    provider.newFolder(rootPath);
    String subdirPath = posix.join(rootPath, 'foo');
    provider.newFolder(subdirPath);
    String path = posix.join(rootPath, 'bar');
    provider.newFile(path, 'contents 1');
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      provider.modifyFile(path, 'contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  Future _delayed(computation()) {
    return new Future.delayed(Duration.ZERO, computation);
  }

  _watchingFolder(String path, test(List<WatchEvent> changesReceived)) {
    Folder folder = provider.getResource(path);
    var changesReceived = <WatchEvent>[];
    folder.changes.listen(changesReceived.add);
    return test(changesReceived);
  }
}
