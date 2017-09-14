// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.file_system.memory_file_system_test;

import 'dart:async';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemExceptionTest);
    defineReflectiveTests(FileTest);
    defineReflectiveTests(FolderTest);
    defineReflectiveTests(MemoryFileSourceExistingTest);
    defineReflectiveTests(MemoryFileSourceNotExistingTest);
    defineReflectiveTests(MemoryResourceProviderTest);
  });
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

  void test_copy() {
    String contents = 'contents';
    File file =
        provider.newFile(provider.convertPath('/foo/file.txt'), contents);
    Folder destination =
        provider.getFolder(provider.convertPath('/destination'));

    File copy = file.copyTo(destination);
    expect(copy.parent, destination);
    expect(copy.shortName, file.shortName);
    expect(copy.readAsStringSync(), contents);
  }

  void test_delete() {
    File file =
        provider.newFile(provider.convertPath('/foo/file.txt'), 'content');
    expect(file.exists, isTrue);
    // delete
    file.delete();
    expect(file.exists, isFalse);
  }

  void test_equals_beforeAndAfterCreate() {
    String path = provider.convertPath('/file.txt');
    File file1 = provider.getResource(path);
    provider.newFile(path, 'contents');
    File file2 = provider.getResource(path);
    expect(file1 == file2, isTrue);
  }

  void test_equals_false() {
    File fileA = provider.getResource(provider.convertPath('/fileA.txt'));
    File fileB = provider.getResource(provider.convertPath('/fileB.txt'));
    expect(fileA == new Object(), isFalse);
    expect(fileA == fileB, isFalse);
  }

  void test_equals_true() {
    File file = provider.getResource(provider.convertPath('/file.txt'));
    expect(file == file, isTrue);
  }

  void test_exists_false() {
    File file = provider.getResource(provider.convertPath('/file.txt'));
    expect(file, isNotNull);
    expect(file.exists, isFalse);
  }

  void test_exists_true() {
    String path = provider.convertPath('/foo/file.txt');
    provider.newFile(path, 'qwerty');
    File file = provider.getResource(path);
    expect(file, isNotNull);
    expect(file.exists, isTrue);
  }

  void test_fullName() {
    String path = provider.convertPath('/foo/bar/file.txt');
    File file = provider.getResource(path);
    expect(file.path, path);
  }

  void test_hashCode() {
    String path = provider.convertPath('/foo/bar/file.txt');
    File file1 = provider.getResource(path);
    provider.newFile(path, 'contents');
    File file2 = provider.getResource(path);
    expect(file1.hashCode, equals(file2.hashCode));
  }

  void test_isOrContains() {
    String path = provider.convertPath('/foo/bar/file.txt');
    File file = provider.getResource(path);
    expect(file.isOrContains(path), isTrue);
    expect(file.isOrContains(provider.convertPath('/foo/bar')), isFalse);
  }

  void test_lengthSync_doesNotExist() {
    File file = provider.getResource(provider.convertPath('/test.txt'));
    expect(() {
      file.lengthSync;
    }, throwsA(_isFileSystemException));
  }

  void test_lengthSync_exists() {
    List<int> bytes = <int>[1, 2, 3, 4, 5];
    File file =
        provider.newFileWithBytes(provider.convertPath('/file.bin'), bytes);
    expect(file.lengthSync, bytes.length);
  }

  void test_modificationStamp_doesNotExist() {
    String path = provider.convertPath('/foo/bar/file.txt');
    File file = provider.newFile(path, 'qwerty');
    provider.deleteFile(path);
    expect(() {
      file.modificationStamp;
    }, throwsA(_isFileSystemException));
  }

  void test_modificationStamp_exists() {
    String path = provider.convertPath('/foo/bar/file.txt');
    File file = provider.newFile(path, 'qwerty');
    expect(file.modificationStamp, isNonNegative);
  }

  void test_parent() {
    String path = provider.convertPath('/foo/bar/file.txt');
    provider.newFile(path, 'content');
    File file = provider.getResource(path);
    Resource parent = file.parent;
    expect(parent, new isInstanceOf<Folder>());
    expect(parent.path, equals(provider.convertPath('/foo/bar')));
  }

  void test_readAsBytesSync_doesNotExist() {
    File file = provider.getResource(provider.convertPath('/test.bin'));
    expect(() {
      file.readAsBytesSync();
    }, throwsA(_isFileSystemException));
  }

  void test_readAsBytesSync_exists() {
    List<int> bytes = <int>[1, 2, 3, 4, 5];
    File file =
        provider.newFileWithBytes(provider.convertPath('/file.bin'), bytes);
    expect(file.readAsBytesSync(), bytes);
  }

  void test_readAsStringSync_doesNotExist() {
    File file = provider.getResource(provider.convertPath('/test.txt'));
    expect(() {
      file.readAsStringSync();
    }, throwsA(_isFileSystemException));
  }

  void test_readAsStringSync_exists() {
    File file = provider.newFile(provider.convertPath('/file.txt'), 'abc');
    expect(file.readAsStringSync(), 'abc');
  }

  void test_renameSync_newDoesNotExist() {
    String oldPath = provider.convertPath('/foo/bar/file.txt');
    String newPath = provider.convertPath('/foo/bar/new-file.txt');
    File file = provider.newFile(oldPath, 'text');
    File newFile = file.renameSync(newPath);
    expect(file.path, oldPath);
    expect(file.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'text');
  }

  void test_renameSync_newExists_file() {
    String oldPath = provider.convertPath('/foo/bar/file.txt');
    String newPath = provider.convertPath('/foo/bar/new-file.txt');
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
    String oldPath = provider.convertPath('/foo/bar/file.txt');
    String newPath = provider.convertPath('/foo/bar/baz');
    File file = provider.newFile(oldPath, 'text');
    provider.newFolder(newPath);
    expect(() {
      file.renameSync(newPath);
    }, throwsA(_isFileSystemException));
    expect(file.path, oldPath);
    expect(file.exists, isTrue);
  }

  void test_resolveSymbolicLinksSync() {
    File file = provider.newFile(provider.convertPath('/test.txt'), 'text');
    expect(file.resolveSymbolicLinksSync(), file);
  }

  void test_shortName() {
    File file = provider.getResource(provider.convertPath('/foo/bar/file.txt'));
    expect(file.shortName, 'file.txt');
  }

  void test_toString() {
    String path = provider.convertPath('/foo/bar/file.txt');
    File file = provider.getResource(path);
    expect(file.toString(), path);
  }

  void test_toUri() {
    String path = provider.convertPath('/foo/file.txt');
    File file = provider.newFile(path, '');
    expect(file.toUri(), provider.pathContext.toUri(path));
  }

  void test_writeAsBytesSync_existing() {
    List<int> content = <int>[1, 2];
    File file = provider.newFileWithBytes(
        provider.convertPath('/foo/file.bin'), content);
    expect(file.readAsBytesSync(), content);
    // write new bytes
    content = <int>[10, 20];
    file.writeAsBytesSync(content);
    expect(file.readAsBytesSync(), content);
  }

  void test_writeAsBytesSync_new() {
    File file = provider.getFile(provider.convertPath('/foo/file.bin'));
    expect(file.exists, false);
    // write new bytes
    List<int> content = <int>[10, 20];
    file.writeAsBytesSync(content);
    expect(file.exists, true);
    expect(file.readAsBytesSync(), content);
  }

  void test_writeAsStringSync_existing() {
    String content = 'ab';
    File file =
        provider.newFile(provider.convertPath('/foo/file.txt'), content);
    expect(file.readAsStringSync(), content);
    // write new bytes
    content = 'CD';
    file.writeAsStringSync(content);
    expect(file.readAsStringSync(), content);
  }

  void test_writeAsStringSync_new() {
    File file = provider.getFile(provider.convertPath('/foo/file.txt'));
    expect(file.exists, false);
    // write new bytes
    String content = 'ef';
    file.writeAsStringSync(content);
    expect(file.exists, true);
    expect(file.readAsStringSync(), content);
  }
}

@reflectiveTest
class FolderTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();
  String path;
  Folder folder;

  void setUp() {
    path = provider.convertPath('/foo/bar');
    folder = provider.newFolder(path);
  }

  void test_canonicalizePath() {
    expect(folder.canonicalizePath(provider.convertPath('baz')),
        equals(provider.convertPath('/foo/bar/baz')));
    expect(folder.canonicalizePath(provider.convertPath('/baz')),
        equals(provider.convertPath('/baz')));
    expect(folder.canonicalizePath(provider.convertPath('../baz')),
        equals(provider.convertPath('/foo/baz')));
    expect(folder.canonicalizePath(provider.convertPath('/a/b/../c')),
        equals(provider.convertPath('/a/c')));
    expect(folder.canonicalizePath(provider.convertPath('./baz')),
        equals(provider.convertPath('/foo/bar/baz')));
    expect(folder.canonicalizePath(provider.convertPath('/a/b/./c')),
        equals(provider.convertPath('/a/b/c')));
  }

  void test_contains() {
    expect(folder.contains(provider.convertPath('/foo/bar/aaa.txt')), isTrue);
    expect(
        folder.contains(provider.convertPath('/foo/bar/aaa/bbb.txt')), isTrue);
    expect(folder.contains(provider.convertPath('/baz.txt')), isFalse);
    expect(folder.contains(provider.convertPath('/foo/bar')), isFalse);
  }

  void test_copy() {
    String sourcePath = provider.convertPath('/source');
    String subdirPath = provider.convertPath('/source/subdir');
    provider.newFolder(sourcePath);
    provider.newFolder(subdirPath);
    provider.newFile(provider.convertPath('/source/file1.txt'), 'file1');
    provider.newFile(provider.convertPath('/source/subdir/file2.txt'), 'file2');
    Folder source = provider.getFolder(sourcePath);
    Folder destination =
        provider.getFolder(provider.convertPath('/destination'));

    Folder copy = source.copyTo(destination);
    expect(copy.parent, destination);
    _verifyStructure(copy, source);
  }

  void test_delete() {
    Folder folder = provider.newFolder(provider.convertPath('/foo'));
    Folder barFolder = provider.newFolder(provider.convertPath('/foo/bar'));
    File aFile = provider.newFile(provider.convertPath('/foo/bar/a.txt'), '');
    File bFile = provider.newFile(provider.convertPath('/foo/b.txt'), '');
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
    String path2 = provider.convertPath('/foo/baz');
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
    provider.newFile(provider.convertPath('/foo/bar/file.txt'), 'content');
    File child = folder.getChild('file.txt');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  void test_getChild_folder() {
    provider.newFolder(provider.convertPath('/foo/bar/baz'));
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
    provider.newFile(provider.convertPath('/foo/bar/name'), 'content');
    File child = folder.getChildAssumingFile('name');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  void test_getChildAssumingFile_folder() {
    provider.newFolder(provider.convertPath('/foo/bar/name'));
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
    provider.newFile(provider.convertPath('/foo/bar/foldername'), 'content');
    Folder child = folder.getChildAssumingFolder('foldername');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFolder_folder() {
    provider.newFolder(provider.convertPath('/foo/bar/foldername'));
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
    provider.newFile(provider.convertPath('/foo/bar/a.txt'), 'aaa');
    provider.newFolder(provider.convertPath('/foo/bar/bFolder'));
    provider.newFile(provider.convertPath('/foo/bar/c.txt'), 'ccc');
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
    expect(folder.isOrContains(provider.convertPath('/foo/bar')), isTrue);
    expect(
        folder.isOrContains(provider.convertPath('/foo/bar/aaa.txt')), isTrue);
    expect(folder.isOrContains(provider.convertPath('/foo/bar/aaa/bbb.txt')),
        isTrue);
    expect(folder.isOrContains(provider.convertPath('/baz.txt')), isFalse);
  }

  void test_parent() {
    Resource parent1 = folder.parent;
    expect(parent1, new isInstanceOf<Folder>());
    expect(parent1.path, equals(provider.convertPath('/foo')));
    Resource parent2 = parent1.parent;
    expect(parent2, new isInstanceOf<Folder>());
    expect(parent2.path, equals(provider.convertPath('/')));
    expect(parent2.parent, isNull);
  }

  void test_toUri() {
    String path = provider.convertPath('/foo/directory');
    Folder folder = provider.newFolder(path);
    expect(folder.toUri(), provider.pathContext.toUri(path));
  }

  /**
   * Verify that the [copy] has the same name and content as the [source].
   */
  void _verifyStructure(Folder copy, Folder source) {
    expect(copy.shortName, source.shortName);
    Map<String, File> sourceFiles = <String, File>{};
    Map<String, Folder> sourceFolders = <String, Folder>{};
    for (Resource child in source.getChildren()) {
      if (child is File) {
        sourceFiles[child.shortName] = child;
      } else if (child is Folder) {
        sourceFolders[child.shortName] = child;
      } else {
        fail('Unknown class of resource: ${child.runtimeType}');
      }
    }
    Map<String, File> copyFiles = <String, File>{};
    Map<String, Folder> copyFolders = <String, Folder>{};
    for (Resource child in source.getChildren()) {
      if (child is File) {
        copyFiles[child.shortName] = child;
      } else if (child is Folder) {
        copyFolders[child.shortName] = child;
      } else {
        fail('Unknown class of resource: ${child.runtimeType}');
      }
    }
    for (String fileName in sourceFiles.keys) {
      File sourceChild = sourceFiles[fileName];
      File copiedChild = copyFiles[fileName];
      if (copiedChild == null) {
        fail('Failed to copy file ${sourceChild.path}');
      }
      expect(copiedChild.readAsStringSync(), sourceChild.readAsStringSync(),
          reason: 'Incorrectly copied file ${sourceChild.path}');
    }
    for (String fileName in sourceFolders.keys) {
      Folder sourceChild = sourceFolders[fileName];
      Folder copiedChild = copyFolders[fileName];
      if (copiedChild == null) {
        fail('Failed to copy folder ${sourceChild.path}');
      }
      _verifyStructure(copiedChild, sourceChild);
    }
  }
}

@reflectiveTest
class MemoryFileSourceExistingTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();
  String path;
  Source source;

  setUp() {
    path = provider.convertPath('/foo/test.dart');
    File file = provider.newFile(path, 'library test;');
    source = file.createSource();
  }

  void test_contents() {
    TimestampedData<String> contents = source.contents;
    expect(contents.data, 'library test;');
  }

  void test_encoding() {
    String expected = 'file:///foo/test.dart';
    if (provider.pathContext.style == pathos.windows.style) {
      expected = 'file:///C:/foo/test.dart';
    }
    expect(source.encoding, expected);
  }

  void test_equals_false_differentFile() {
    File fileA = provider.newFile(provider.convertPath('/foo/a.dart'), '');
    File fileB = provider.newFile(provider.convertPath('/foo/b.dart'), '');
    Source sourceA = fileA.createSource();
    Source sourceB = fileB.createSource();
    expect(sourceA == sourceB, isFalse);
  }

  void test_equals_false_notMemorySource() {
    File file = provider.newFile(path, '');
    Source source = file.createSource();
    expect(source == new Object(), isFalse);
  }

  void test_equals_true_sameFile() {
    File file = provider.newFile(path, '');
    Source sourceA = file.createSource();
    Source sourceB = file.createSource();
    expect(sourceA == sourceB, isTrue);
  }

  void test_equals_true_self() {
    File file = provider.newFile(path, '');
    Source source = file.createSource();
    expect(source == source, isTrue);
  }

  void test_exists() {
    expect(source.exists(), isTrue);
  }

  void test_fullName() {
    expect(source.fullName, path);
  }

  void test_hashCode() {
    source.hashCode;
  }

  void test_resolveRelative() {
    Uri relative = resolveRelativeUri(
        source.uri,
        provider.pathContext
            .toUri(provider.pathContext.join('bar', 'baz.dart')));
    expect(relative,
        provider.pathContext.toUri(provider.convertPath('/foo/bar/baz.dart')));
  }

  void test_resolveRelative_dart() {
    File file =
        provider.newFile(provider.convertPath('/sdk/lib/core/core.dart'), '');
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
  String path;
  Source source;

  setUp() {
    path = provider.convertPath('/foo/test.dart');
    File file = provider.getResource(path);
    source = file.createSource();
  }

  void test_contents() {
    expect(() {
      source.contents;
    }, throwsA(_isFileSystemException));
  }

  void test_encoding() {
    String expected = 'file:///foo/test.dart';
    if (provider.pathContext.style == pathos.windows.style) {
      expected = 'file:///C:/foo/test.dart';
    }
    expect(source.encoding, expected);
  }

  void test_exists() {
    expect(source.exists(), isFalse);
  }

  void test_fullName() {
    expect(source.fullName, path);
  }

  void test_modificationStamp() {
    expect(source.modificationStamp, -1);
  }

  void test_resolveRelative() {
    Uri relative = resolveRelativeUri(
        source.uri,
        provider.pathContext
            .toUri(provider.pathContext.join('bar', 'baz.dart')));
    expect(relative,
        provider.pathContext.toUri(provider.convertPath('/foo/bar/baz.dart')));
  }

  void test_shortName() {
    expect(source.shortName, 'test.dart');
  }
}

@reflectiveTest
class MemoryResourceProviderTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();

  void test_deleteFile_folder() {
    String path = provider.convertPath('/my/file');
    provider.newFolder(path);
    expect(() {
      provider.deleteFile(path);
    }, throwsArgumentError);
    expect(provider.getResource(path), new isInstanceOf<Folder>());
  }

  void test_deleteFile_notExistent() {
    String path = provider.convertPath('/my/file');
    expect(() {
      provider.deleteFile(path);
    }, throwsArgumentError);
    Resource file = provider.getResource(path);
    expect(file, isNotNull);
    expect(file.exists, isFalse);
  }

  void test_deleteFile_success() {
    String path = provider.convertPath('/my/file');
    provider.newFile(path, 'contents');
    Resource file = provider.getResource(path);
    expect(file, new isInstanceOf<File>());
    expect(file.exists, isTrue);
    provider.deleteFile(path);
    expect(file.exists, isFalse);
  }

  test_getFolder_existing() async {
    String path = provider.convertPath('/foo/bar');
    provider.newFolder(path);
    Folder folder = provider.getFolder(path);
    expect(folder, isNotNull);
    expect(folder.path, path);
    expect(folder.exists, isTrue);
  }

  test_getFolder_notExisting() async {
    String path = provider.convertPath('/foo/bar');
    Folder folder = provider.getFolder(path);
    expect(folder, isNotNull);
    expect(folder.path, path);
    expect(folder.exists, isFalse);
  }

  test_getModificationTimes() async {
    File file = provider.newFile(provider.convertPath('/test.dart'), '');
    Source source = file.createSource();
    List<int> times = await provider.getModificationTimes([source]);
    expect(times, [source.modificationStamp]);
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
    String path = provider.convertPath('/my/file');
    provider.newFolder(path);
    expect(() {
      provider.modifyFile(path, 'contents');
    }, throwsArgumentError);
    expect(provider.getResource(path), new isInstanceOf<Folder>());
  }

  void test_modifyFile_notExistent() {
    String path = provider.convertPath('/my/file');
    expect(() {
      provider.modifyFile(path, 'contents');
    }, throwsArgumentError);
    Resource file = provider.getResource(path);
    expect(file, isNotNull);
    expect(file.exists, isFalse);
  }

  void test_modifyFile_success() {
    String path = provider.convertPath('/my/file');
    provider.newFile(path, 'contents 1');
    Resource file = provider.getResource(path);
    expect(file, new isInstanceOf<File>());
    Source source = (file as File).createSource();
    expect(source.contents.data, equals('contents 1'));
    provider.modifyFile(path, 'contents 2');
    expect(source.contents.data, equals('contents 2'));
  }

  void test_newFileWithBytes() {
    String path = provider.convertPath('/my/file');
    List<int> bytes = <int>[1, 2, 3, 4, 5];
    provider.newFileWithBytes(path, bytes);
    File file = provider.getResource(path);
    expect(file, isNotNull);
    expect(file.exists, isTrue);
    expect(file.readAsBytesSync(), bytes);
  }

  void test_newFolder_alreadyExists_asFile() {
    provider.newFile(provider.convertPath('/my/file'), 'qwerty');
    expect(() {
      provider.newFolder(provider.convertPath('/my/file'));
    }, throwsArgumentError);
  }

  void test_newFolder_alreadyExists_asFolder() {
    String path = provider.convertPath('/my/folder');
    Folder folder = provider.newFolder(path);
    Folder newFolder = provider.newFolder(path);
    expect(newFolder, folder);
  }

  void test_newFolder_emptyPath() {
    expect(() {
      provider.newFolder('');
    }, throwsArgumentError);
  }

  void test_newFolder_notAbsolute() {
    expect(() {
      provider.newFolder('not/absolute');
    }, throwsArgumentError);
  }

  test_watch_createFile() {
    String rootPath = provider.convertPath('/my/path');
    provider.newFolder(rootPath);
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      String path = provider.pathContext.join(rootPath, 'foo');
      provider.newFile(path, 'contents');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.ADD));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watch_deleteFile() {
    String rootPath = provider.convertPath('/my/path');
    provider.newFolder(rootPath);
    String path = provider.pathContext.join(rootPath, 'foo');
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
    String rootPath = provider.convertPath('/my/path');
    provider.newFolder(rootPath);
    String path = provider.pathContext.join(rootPath, 'foo');
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
    String rootPath = provider.convertPath('/my/path');
    provider.newFolder(rootPath);
    String subdirPath = provider.pathContext.join(rootPath, 'foo');
    provider.newFolder(subdirPath);
    String path = provider.pathContext.join(rootPath, 'bar');
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
