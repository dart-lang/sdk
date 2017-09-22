// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.file_system.physical_resource_provider_test;

import 'dart:async';
import 'dart:core';
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

main() {
  if (!new bool.fromEnvironment('skipPhysicalResourceProviderTests')) {
    defineReflectiveSuite(() {
      defineReflectiveTests(PhysicalResourceProviderTest);
      defineReflectiveTests(FileTest);
      defineReflectiveTests(FolderTest);
    });
  }
}

var _isFile = new isInstanceOf<File>();
var _isFileSystemException = new isInstanceOf<FileSystemException>();
var _isFolder = new isInstanceOf<Folder>();

String join(String part1, [String part2, String part3]) =>
    pathos.join(part1, part2, part3);

@reflectiveTest
class FileTest extends _BaseTest {
  String path;
  File file;

  setUp() {
    super.setUp();
    path = join(tempPath, 'file.txt');
    file = PhysicalResourceProvider.INSTANCE.getResource(path);
  }

  void test_copy() {
    PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
    String contents = 'contents';
    new io.File(path).writeAsStringSync(contents);
    Folder destination = provider.getFolder(join(tempPath, 'destination'));

    File copy = file.copyTo(destination);
    expect(copy.parent, destination);
    expect(copy.shortName, file.shortName);
    expect(copy.readAsStringSync(), contents);
  }

  void test_createSource() {
    new io.File(path).writeAsStringSync('contents');
    Source source = file.createSource();
    expect(source.uriKind, UriKind.FILE_URI);
    expect(source.exists(), isTrue);
    expect(source.contents.data, 'contents');
  }

  void test_delete() {
    new io.File(path).writeAsStringSync('contents');
    expect(file.exists, isTrue);
    // delete
    file.delete();
    expect(file.exists, isFalse);
  }

  void test_equals_differentPaths() {
    String path2 = join(tempPath, 'file2.txt');
    File file2 = PhysicalResourceProvider.INSTANCE.getResource(path2);
    expect(file == file2, isFalse);
  }

  void test_equals_samePath() {
    new io.File(path).writeAsStringSync('contents');
    File file2 = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(file == file2, isTrue);
  }

  void test_exists_false() {
    expect(file.exists, isFalse);
  }

  void test_exists_true() {
    new io.File(path).writeAsStringSync('contents');
    expect(file.exists, isTrue);
  }

  void test_fullName() {
    expect(file.path, path);
  }

  void test_hashCode() {
    new io.File(path).writeAsStringSync('contents');
    File file2 = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(file.hashCode, equals(file2.hashCode));
  }

  void test_isOrContains() {
    File file = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(file.isOrContains(path), isTrue);
    expect(file.isOrContains('foo'), isFalse);
  }

  void test_lengthSync_doesNotExist() {
    File file = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(() {
      file.lengthSync;
    }, throwsA(_isFileSystemException));
  }

  void test_lengthSync_exists() {
    List<int> bytes = <int>[1, 2, 3, 4, 5];
    new io.File(path).writeAsBytesSync(bytes);
    expect(file.lengthSync, bytes.length);
  }

  void test_modificationStamp_doesNotExist() {
    File file = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(() {
      file.modificationStamp;
    }, throwsA(_isFileSystemException));
  }

  void test_modificationStamp_exists() {
    new io.File(path).writeAsStringSync('contents');
    File file = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(file.modificationStamp, isNonNegative);
  }

  void test_parent() {
    Resource parent = file.parent;
    expect(parent, new isInstanceOf<Folder>());
    expect(parent.path, equals(tempPath));
  }

  void test_readAsBytesSync_doesNotExist() {
    File file = PhysicalResourceProvider.INSTANCE.getResource('/test.bin');
    expect(() {
      file.readAsBytesSync();
    }, throwsA(_isFileSystemException));
  }

  void test_readAsBytesSync_exists() {
    List<int> bytes = <int>[1, 2, 3, 4, 5];
    new io.File(path).writeAsBytesSync(bytes);
    expect(file.readAsBytesSync(), bytes);
  }

  void test_readAsStringSync_doesNotExist() {
    File file = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(() {
      file.readAsStringSync();
    }, throwsA(_isFileSystemException));
  }

  void test_readAsStringSync_exists() {
    new io.File(path).writeAsStringSync('abc');
    File file = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(file.readAsStringSync(), 'abc');
  }

  void test_renameSync_newDoesNotExist() {
    pathos.Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    String oldPath = pathContext.join(tempPath, 'file.txt');
    String newPath = pathContext.join(tempPath, 'new-file.txt');
    new io.File(oldPath).writeAsStringSync('text');
    File file = PhysicalResourceProvider.INSTANCE.getResource(oldPath);
    File newFile = file.renameSync(newPath);
    expect(file.path, oldPath);
    expect(file.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'text');
  }

  test_renameSync_newExists_file() async {
    pathos.Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    String oldPath = pathContext.join(tempPath, 'file.txt');
    String newPath = pathContext.join(tempPath, 'new-file.txt');
    new io.File(oldPath).writeAsStringSync('text');
    new io.File(newPath).writeAsStringSync('new text');
    File file = PhysicalResourceProvider.INSTANCE.getResource(oldPath);
    File newFile = file.renameSync(newPath);
    expect(file.path, oldPath);
    expect(file.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'text');
  }

  void test_renameSync_newExists_folder() {
    pathos.Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    String oldPath = pathContext.join(tempPath, 'file.txt');
    String newPath = pathContext.join(tempPath, 'foo');
    new io.File(oldPath).writeAsStringSync('text');
    new io.Directory(newPath).createSync();
    File file = PhysicalResourceProvider.INSTANCE.getResource(oldPath);
    expect(() {
      file.renameSync(newPath);
    }, throwsA(_isFileSystemException));
    expect(file.path, oldPath);
    expect(file.exists, isTrue);
  }

  void test_resolveSymbolicLinksSync_links() {
    pathos.Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    String pathA = pathContext.join(tempPath, 'a');
    String pathB = pathContext.join(pathA, 'b');
    new io.Directory(pathB).createSync(recursive: true);
    String filePath = pathContext.join(pathB, 'test.txt');
    io.File testFile = new io.File(filePath);
    testFile.writeAsStringSync('test');

    String pathC = pathContext.join(tempPath, 'c');
    String pathD = pathContext.join(pathC, 'd');
    new io.Link(pathD).createSync(pathA, recursive: true);

    String pathE = pathContext.join(tempPath, 'e');
    String pathF = pathContext.join(pathE, 'f');
    new io.Link(pathF).createSync(pathC, recursive: true);

    String linkPath =
        pathContext.join(tempPath, 'e', 'f', 'd', 'b', 'test.txt');
    File file = PhysicalResourceProvider.INSTANCE.getFile(linkPath);
    expect(file.resolveSymbolicLinksSync().path,
        testFile.resolveSymbolicLinksSync());
  }

  void test_resolveSymbolicLinksSync_noLinks() {
    //
    // On some platforms the path to the temp directory includes a symbolic
    // link. We remove that from the equation before creating the File in order
    // to show that the operation works as expected without symbolic links.
    //
    io.File ioFile = new io.File(path);
    ioFile.writeAsStringSync('test');
    file = PhysicalResourceProvider.INSTANCE
        .getFile(ioFile.resolveSymbolicLinksSync());
    expect(file.resolveSymbolicLinksSync(), file);
  }

  void test_shortName() {
    expect(file.shortName, 'file.txt');
  }

  void test_toString() {
    expect(file.toString(), path);
  }

  void test_toUri() {
    String path = io.Platform.isWindows ? r'C:\foo\file.txt' : '/foo/file.txt';
    File file = PhysicalResourceProvider.INSTANCE.getFile(path);
    expect(file.toUri(), new Uri.file(path));
  }

  void test_writeAsBytesSync() {
    List<int> content = <int>[1, 2];
    new io.File(path).writeAsBytesSync(content);
    expect(file.readAsBytesSync(), content);
    // write new bytes
    content = <int>[10, 20];
    file.writeAsBytesSync(content);
    expect(file.readAsBytesSync(), content);
  }

  void test_writeAsStringSync() {
    String content = 'ab';
    new io.File(path).writeAsStringSync(content);
    expect(file.readAsStringSync(), content);
    // write new bytes
    content = 'CD';
    file.writeAsStringSync(content);
    expect(file.readAsStringSync(), content);
  }
}

@reflectiveTest
class FolderTest extends _BaseTest {
  String path;
  Folder folder;

  setUp() {
    super.setUp();
    path = join(tempPath, 'folder');
    new io.Directory(path).createSync();
    folder = PhysicalResourceProvider.INSTANCE.getResource(path);
  }

  void test_canonicalizePath() {
    String path2 = join(tempPath, 'folder2');
    String path3 = join(tempPath, 'folder3');
    expect(folder.canonicalizePath('baz'), equals(join(path, 'baz')));
    expect(folder.canonicalizePath(path2), equals(path2));
    expect(folder.canonicalizePath(join('..', 'folder2')), equals(path2));
    expect(
        folder.canonicalizePath(join(path2, '..', 'folder3')), equals(path3));
    expect(
        folder.canonicalizePath(join('.', 'baz')), equals(join(path, 'baz')));
    expect(folder.canonicalizePath(join(path2, '.', 'baz')),
        equals(join(path2, 'baz')));
  }

  void test_contains() {
    expect(folder.contains(join(path, 'aaa.txt')), isTrue);
    expect(folder.contains(join(path, 'aaa', 'bbb.txt')), isTrue);
    expect(folder.contains(join(tempPath, 'baz.txt')), isFalse);
    expect(folder.contains(path), isFalse);
  }

  void test_copy() {
    PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
    String sourcePath = join(tempPath, 'source');
    String subdirPath = join(sourcePath, 'subdir');
    new io.Directory(sourcePath).createSync();
    new io.Directory(subdirPath).createSync();
    new io.File(join(sourcePath, 'file1.txt')).writeAsStringSync('file1');
    new io.File(join(subdirPath, 'file2.txt')).writeAsStringSync('file2');
    Folder source = provider.getFolder(sourcePath);
    Folder destination = provider.getFolder(join(tempPath, 'destination'));

    Folder copy = source.copyTo(destination);
    expect(copy.parent, destination);
    _verifyStructure(copy, source);
  }

  void test_delete() {
    new io.File(join(path, 'myFile')).createSync();
    var child = folder.getChild('myFile');
    expect(child, _isFile);
    expect(child.exists, isTrue);
    // delete "folder"
    folder.delete();
    expect(child.exists, isFalse);
  }

  void test_equals_differentPaths() {
    String path2 = join(tempPath, 'folder2');
    new io.Directory(path2).createSync();
    Folder folder2 = PhysicalResourceProvider.INSTANCE.getResource(path2);
    expect(folder == folder2, isFalse);
  }

  void test_equals_samePath() {
    Folder folder2 = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(folder == folder2, isTrue);
  }

  void test_getChild_doesNotExist() {
    var child = folder.getChild('no-such-resource');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChild_file() {
    new io.File(join(path, 'myFile')).createSync();
    var child = folder.getChild('myFile');
    expect(child, _isFile);
    expect(child.exists, isTrue);
  }

  void test_getChild_folder() {
    new io.Directory(join(path, 'myFolder')).createSync();
    var child = folder.getChild('myFolder');
    expect(child, _isFolder);
    expect(child.exists, isTrue);
  }

  void test_getChildAssumingFile_doesNotExist() {
    File child = folder.getChildAssumingFile('no-such-resource');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFile_file() {
    new io.File(join(path, 'myFile')).createSync();
    File child = folder.getChildAssumingFile('myFile');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  void test_getChildAssumingFile_folder() {
    new io.Directory(join(path, 'myFolder')).createSync();
    File child = folder.getChildAssumingFile('myFolder');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFolder_doesNotExist() {
    Folder child = folder.getChildAssumingFolder('no-such-resource');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFolder_file() {
    new io.File(join(path, 'myFile')).createSync();
    Folder child = folder.getChildAssumingFolder('myFile');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  void test_getChildAssumingFolder_folder() {
    new io.Directory(join(path, 'myFolder')).createSync();
    Folder child = folder.getChildAssumingFolder('myFolder');
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
    // create 2 files and 1 folder
    new io.File(join(path, 'a.txt')).createSync();
    new io.Directory(join(path, 'bFolder')).createSync();
    new io.File(join(path, 'c.txt')).createSync();
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
    Folder folder2 = PhysicalResourceProvider.INSTANCE.getResource(path);
    expect(folder.hashCode, equals(folder2.hashCode));
  }

  void test_isOrContains() {
    expect(folder.isOrContains(path), isTrue);
    expect(folder.isOrContains(join(path, 'aaa.txt')), isTrue);
    expect(folder.isOrContains(join(path, 'aaa', 'bbb.txt')), isTrue);
    expect(folder.isOrContains(join(tempPath, 'baz.txt')), isFalse);
  }

  void test_parent() {
    Resource parent = folder.parent;
    expect(parent, new isInstanceOf<Folder>());
    expect(parent.path, equals(tempPath));

    // Since the OS is in control of where tempPath is, we don't know how
    // far it should be from the root.  So just verify that each call to
    // parent results in a a folder with a shorter path, and that we
    // reach the root eventually.
    while (true) {
      Resource grandParent = parent.parent;
      if (grandParent == null) {
        break;
      }
      expect(grandParent, new isInstanceOf<Folder>());
      expect(grandParent.path.length, lessThan(parent.path.length));
      parent = grandParent;
    }
  }

  void test_toUri() {
    String path =
        io.Platform.isWindows ? r'C:\foo\directory' : '/foo/directory';
    Folder folder = PhysicalResourceProvider.INSTANCE.getFolder(path);
    expect(folder.toUri(), new Uri.directory(path));
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
class PhysicalResourceProviderTest extends _BaseTest {
  test_getFolder_trailingSeparator() {
    String path = tempPath;
    PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
    Folder folder = provider.getFolder('$path${pathos.separator}');
    expect(folder.path, path);
  }

  test_getModificationTimes() async {
    PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
    String path = join(tempPath, 'file1.txt');
    new io.File(path).writeAsStringSync('');
    Source source = provider.getFile(path).createSource();
    List<int> times = await provider.getModificationTimes([source]);
    expect(times, [source.modificationStamp]);
  }

  void test_getStateLocation_uniqueness() {
    PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
    String idOne = 'one';
    Folder folderOne = provider.getStateLocation(idOne);
    expect(folderOne, isNotNull);
    String idTwo = 'two';
    Folder folderTwo = provider.getStateLocation(idTwo);
    expect(folderTwo, isNotNull);
    expect(folderTwo, isNot(equals(folderOne)));
    expect(provider.getStateLocation(idOne), equals(folderOne));
  }

  test_watchFile_delete() {
    var path = join(tempPath, 'foo');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFile(path, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.deleteSync();
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        if (io.Platform.isWindows) {
          // See https://github.com/dart-lang/sdk/issues/23762
          // Not sure why this breaks under Windows, but testing to see whether
          // we are running Windows causes the type to change. For now we print
          // the type out of curiosity.
          print(
              'PhysicalResourceProviderTest:test_watchFile_delete received an event with type = ${changesReceived[0].type}');
        } else {
          expect(changesReceived[0].type, equals(ChangeType.REMOVE));
        }
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watchFile_modify() {
    var path = join(tempPath, 'foo');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFile(path, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watchFolder_createFile() {
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      var path = join(tempPath, 'foo');
      new io.File(path).writeAsStringSync('contents');
      return _delayed(() {
        // There should be an "add" event indicating that the file was added.
        // Depending on how long it took to write the contents, it may be
        // followed by "modify" events.
        expect(changesReceived, isNotEmpty);
        expect(changesReceived[0].type, equals(ChangeType.ADD));
        expect(changesReceived[0].path, equals(path));
        for (int i = 1; i < changesReceived.length; i++) {
          expect(changesReceived[i].type, equals(ChangeType.MODIFY));
          expect(changesReceived[i].path, equals(path));
        }
      });
    });
  }

  test_watchFolder_deleteFile() {
    var path = join(tempPath, 'foo');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.deleteSync();
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.REMOVE));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watchFolder_modifyFile() {
    var path = join(tempPath, 'foo');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watchFolder_modifyFile_inSubDir() {
    var fooPath = join(tempPath, 'foo');
    new io.Directory(fooPath).createSync();
    var path = join(tempPath, 'bar');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  Future _delayed(computation()) {
    // Give the tests 1 second to detect the changes. While it may only
    // take up to a few hundred ms, a whole second gives a good margin
    // for when running tests.
    return new Future.delayed(new Duration(seconds: 1), computation);
  }

  _watchingFile(String path, test(List<WatchEvent> changesReceived)) {
    // Delay before we start watching the file.  This is necessary
    // because on MacOS, file modifications that occur just before we
    // start watching are sometimes misclassified as happening just after
    // we start watching.
    return _delayed(() {
      File file = PhysicalResourceProvider.INSTANCE.getResource(path);
      var changesReceived = <WatchEvent>[];
      var subscription = file.changes.listen(changesReceived.add);
      // Delay running the rest of the test to allow file.changes propagate.
      return _delayed(() => test(changesReceived)).whenComplete(() {
        subscription.cancel();
      });
    });
  }

  _watchingFolder(String path, test(List<WatchEvent> changesReceived)) {
    // Delay before we start watching the folder.  This is necessary
    // because on MacOS, file modifications that occur just before we
    // start watching are sometimes misclassified as happening just after
    // we start watching.
    return _delayed(() {
      Folder folder = PhysicalResourceProvider.INSTANCE.getResource(path);
      var changesReceived = <WatchEvent>[];
      var subscription = folder.changes.listen(changesReceived.add);
      // Delay running the rest of the test to allow folder.changes to
      // take a snapshot of the current directory state.  Otherwise it
      // won't be able to reliably distinguish new files from modified
      // ones.
      return _delayed(() => test(changesReceived)).whenComplete(() {
        subscription.cancel();
      });
    });
  }
}

class _BaseTest {
  io.Directory tempDirectory;
  String tempPath;

  setUp() {
    tempDirectory = io.Directory.systemTemp.createTempSync('test_resource');
    tempPath = tempDirectory.absolute.path;
  }

  tearDown() {
    tempDirectory.deleteSync(recursive: true);
  }
}
