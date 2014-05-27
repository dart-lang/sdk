// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.resource;

import 'dart:io' as io;

import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

main() {
  groupSep = ' | ';

  group('MemoryResourceProvider', () {
    MemoryResourceProvider provider;

    setUp(() {
      provider = new MemoryResourceProvider();
    });

    group('File', () {
      group('==', () {
        test('false', () {
          File fileA = provider.getResource('/fileA.txt');
          File fileB = provider.getResource('/fileB.txt');
          expect(fileA == new Object(), isFalse);
          expect(fileA == fileB, isFalse);
        });

        test('true', () {
          File file = provider.getResource('/file.txt');
          expect(file == file, isTrue);
        });
      });

      group('exists', () {
        test('false', () {
          File file = provider.getResource('/file.txt');
          expect(file, isNotNull);
          expect(file.exists, isFalse);
        });

        test('true', () {
          provider.newFile('/foo/file.txt', 'qwerty');
          File file = provider.getResource('/foo/file.txt');
          expect(file, isNotNull);
          expect(file.exists, isTrue);
        });
      });

      test('fullName', () {
        File file = provider.getResource('/foo/bar/file.txt');
        expect(file.fullName, '/foo/bar/file.txt');
      });

      test('hashCode', () {
        File file = provider.getResource('/foo/bar/file.txt');
        file.hashCode;
      });

      test('shortName', () {
        File file = provider.getResource('/foo/bar/file.txt');
        expect(file.shortName, 'file.txt');
      });

      test('toString', () {
        File file = provider.getResource('/foo/bar/file.txt');
        expect(file.toString(), '/foo/bar/file.txt');
      });
    });

    group('Folder', () {
      Folder folder;

      setUp(() {
        folder = provider.newFolder('/foo/bar');
      });

      group('getChild', () {
        test('does not exist', () {
          File file = folder.getChild('file.txt');
          expect(file, isNotNull);
          expect(file.exists, isFalse);
        });

        test('file', () {
          provider.newFile('/foo/bar/file.txt', 'content');
          File child = folder.getChild('file.txt');
          expect(child, isNotNull);
          expect(child.exists, isTrue);
        });

        test('folder', () {
          provider.newFolder('/foo/bar/baz');
          Folder child = folder.getChild('baz');
          expect(child, isNotNull);
          expect(child.exists, isTrue);
        });
      });

      test('getChildren', () {
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
      });
    });

    group('_MemoryFileSource', () {
      Source source;

      group('existent', () {
        setUp(() {
          File file = provider.newFile('/foo/test.dart', 'library test;');
          source = file.createSource(UriKind.FILE_URI);
        });

        group('==', () {
          group('true', () {
            test('self', () {
              File file = provider.newFile('/foo/test.dart', '');
              Source source = file.createSource(UriKind.FILE_URI);
              expect(source == source, isTrue);
            });

            test('same file', () {
              File file = provider.newFile('/foo/test.dart', '');
              Source sourceA = file.createSource(UriKind.FILE_URI);
              Source sourceB = file.createSource(UriKind.FILE_URI);
              expect(sourceA == sourceB, isTrue);
            });
          });

          group('false', () {
            test('not a memory Source', () {
              File file = provider.newFile('/foo/test.dart', '');
              Source source = file.createSource(UriKind.FILE_URI);
              expect(source == new Object(), isFalse);
            });

            test('different file', () {
              File fileA = provider.newFile('/foo/a.dart', '');
              File fileB = provider.newFile('/foo/b.dart', '');
              Source sourceA = fileA.createSource(UriKind.FILE_URI);
              Source sourceB = fileB.createSource(UriKind.FILE_URI);
              expect(sourceA == sourceB, isFalse);
            });
          });
        });

        test('contents', () {
          TimestampedData<String> contents = source.contents;
          expect(contents.data, 'library test;');
        });

        test('encoding', () {
          expect(source.encoding, 'f/foo/test.dart');
        });

        test('exists', () {
          expect(source.exists(), isTrue);
        });

        test('fullName', () {
          expect(source.fullName, '/foo/test.dart');
        });

        test('hashCode', () {
          source.hashCode;
        });

        test('shortName', () {
          expect(source.shortName, 'test.dart');
        });

        test('resolveRelative', () {
          var relative = source.resolveRelative(new Uri.file('bar/baz.dart'));
          expect(relative.fullName, '/foo/bar/baz.dart');
        });
      });

      group('non-existent', () {
        setUp(() {
          File file = provider.getResource('/foo/test.dart');
          source = file.createSource(UriKind.FILE_URI);
        });

        test('contents', () {
          expect(
            () {
              source.contents;
            },
            throwsA(_isMemoryResourceException)
          );
        });

        test('encoding', () {
          expect(source.encoding, 'f/foo/test.dart');
        });

        test('exists', () {
          expect(source.exists(), isFalse);
        });

        test('fullName', () {
          expect(source.fullName, '/foo/test.dart');
        });

        test('shortName', () {
          expect(source.shortName, 'test.dart');
        });

        test('resolveRelative', () {
          var relative = source.resolveRelative(new Uri.file('bar/baz.dart'));
          expect(relative.fullName, '/foo/bar/baz.dart');
        });
      });
    });
  });

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
        expect(file.fullName, path);
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
