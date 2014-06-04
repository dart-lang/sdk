// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.physical.resource.provider;

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';
import 'package:watcher/watcher.dart';

main() {
  groupSep = ' | ';

  group('PhysicalResourceProvider', () {
      io.Directory tempDirectory;
      String tempPath;

      setUp(() {
        tempDirectory = io.Directory.systemTemp.createTempSync('test_resource');
        tempPath = tempDirectory.absolute.path;
      });

      tearDown(() {
        tempDirectory.deleteSync(recursive: true);
      });

      group('Watch', () {

        Future delayed(computation()) {
          return new Future.delayed(
              new Duration(milliseconds: 100), computation);
        }

        watchingFolder(String path, test(List<WatchEvent> changesReceived)) {
          // Delay before we start watching the folder.  This is necessary
          // because on MacOS, file modifications that occur just before we start
          // watching are sometimes misclassified as happening just after we
          // start watching.
          return delayed(() {
            Folder folder = PhysicalResourceProvider.INSTANCE.getResource(path);
            var changesReceived = <WatchEvent>[];
            var subscription = folder.changes.listen(changesReceived.add);
            // Delay running the rest of the test to allow folder.changes to take
            // a snapshot of the current directory state.  Otherwise it won't be
            // able to reliably distinguish new files from modified ones.
            return delayed(() => test(changesReceived)).whenComplete(() {
              subscription.cancel();
            });
          });
        }

        test('create file', () => watchingFolder(tempPath, (changesReceived) {
          expect(changesReceived, hasLength(0));
          var path = join(tempPath, 'foo');
          new io.File(path).writeAsStringSync('contents');
          return delayed(() {
            expect(changesReceived, hasLength(1));
            expect(changesReceived[0].type, equals(ChangeType.ADD));
            expect(changesReceived[0].path, equals(path));
          });
        }));

        test('modify file', () {
          var path = join(tempPath, 'foo');
          var file = new io.File(path);
          file.writeAsStringSync('contents 1');
          return watchingFolder(tempPath, (changesReceived) {
            expect(changesReceived, hasLength(0));
            file.writeAsStringSync('contents 2');
            return delayed(() {
              expect(changesReceived, hasLength(1));
              expect(changesReceived[0].type, equals(ChangeType.MODIFY));
              expect(changesReceived[0].path, equals(path));
            });
          });
        });

        test('modify file in subdir', () {
          var subdirPath = join(tempPath, 'foo');
          new io.Directory(subdirPath).createSync();
          var path = join(tempPath, 'bar');
          var file = new io.File(path);
          file.writeAsStringSync('contents 1');
          return watchingFolder(tempPath, (changesReceived) {
            expect(changesReceived, hasLength(0));
            file.writeAsStringSync('contents 2');
            return delayed(() {
              expect(changesReceived, hasLength(1));
              expect(changesReceived[0].type, equals(ChangeType.MODIFY));
              expect(changesReceived[0].path, equals(path));
            });
          });
        });

        test('delete file', () {
          var path = join(tempPath, 'foo');
          var file = new io.File(path);
          file.writeAsStringSync('contents 1');
          return watchingFolder(tempPath, (changesReceived) {
            expect(changesReceived, hasLength(0));
            file.deleteSync();
            return delayed(() {
              expect(changesReceived, hasLength(1));
              expect(changesReceived[0].type, equals(ChangeType.REMOVE));
              expect(changesReceived[0].path, equals(path));
            });
          });
        });
      });

      group('File', () {
        String path;
        File file;

        setUp(() {
          path = join(tempPath, 'file.txt');
          file = PhysicalResourceProvider.INSTANCE.getResource(path);
        });

        test('createSource', () {
          new io.File(path).writeAsStringSync('contents');
          var source = file.createSource(UriKind.FILE_URI);
          expect(source.uriKind, UriKind.FILE_URI);
          expect(source.exists(), isTrue);
          expect(source.contents.data, 'contents');
        });

        group('exists', () {
          test('false', () {
            expect(file.exists, isFalse);
          });

          test('true', () {
            new io.File(path).writeAsStringSync('contents');
            expect(file.exists, isTrue);
          });
        });

        test('fullName', () {
          expect(file.path, path);
        });

        test('hashCode', () {
          file.hashCode;
        });

        test('shortName', () {
          expect(file.shortName, 'file.txt');
        });

        test('toString', () {
          expect(file.toString(), path);
        });
      });

      group('Folder', () {
        String path;
        Folder folder;

        setUp(() {
          path = join(tempPath, 'folder');
          new io.Directory(path).createSync();
          folder = PhysicalResourceProvider.INSTANCE.getResource(path);
        });

        group('getChild', () {
          test('does not exist', () {
            var child = folder.getChild('no-such-resource');
            expect(child, isNotNull);
            expect(child.exists, isFalse);
          });

          test('file', () {
            new io.File(join(path, 'myFile')).createSync();
            var child = folder.getChild('myFile');
            expect(child, _isFile);
            expect(child.exists, isTrue);
          });

          test('folder', () {
            new io.Directory(join(path, 'myFolder')).createSync();
            var child = folder.getChild('myFolder');
            expect(child, _isFolder);
            expect(child.exists, isTrue);
          });
        });

        test('getChildren', () {
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
        });
      });
    });
}

var _isFile = new isInstanceOf<File>();
var _isFolder = new isInstanceOf<Folder>();
var _isMemoryResourceException = new isInstanceOf<MemoryResourceException>();
