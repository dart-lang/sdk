// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.resource;

import 'dart:async';

import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';
import 'package:watcher/watcher.dart';

import 'mocks.dart';


var _isFile = new isInstanceOf<File>();
var _isFolder = new isInstanceOf<Folder>();
var _isMemoryResourceException = new isInstanceOf<MemoryResourceException>();


main() {
  groupSep = ' | ';

  group('MemoryResourceProvider', () {
    MemoryResourceProvider provider;

    setUp(() {
      provider = new MemoryResourceProvider();
    });

    test('MemoryResourceException', () {
      var exception = new MemoryResourceException('/my/path', 'my message');
      expect(exception.path, '/my/path');
      expect(exception.message, 'my message');
      expect(exception.toString(),
          'MemoryResourceException(path=/my/path; message=my message)');
    });

    group('Watch', () {

      Future delayed(computation()) {
        return pumpEventQueue().then((_) => computation());
      }

      watchingFolder(String path, test(List<WatchEvent> changesReceived)) {
        Folder folder = provider.getResource(path);
        var changesReceived = <WatchEvent>[];
        folder.changes.listen(changesReceived.add);
        return test(changesReceived);
      }

      test('create file', () {
        String rootPath = '/my/path';
        provider.newFolder(rootPath);
        watchingFolder(rootPath, (changesReceived) {
          expect(changesReceived, hasLength(0));
          String path = posix.join(rootPath, 'foo');
          provider.newFile(path, 'contents');
          return delayed(() {
            expect(changesReceived, hasLength(1));
            expect(changesReceived[0].type, equals(ChangeType.ADD));
            expect(changesReceived[0].path, equals(path));
          });
        });
      });

      test('modify file', () {
        String rootPath = '/my/path';
        provider.newFolder(rootPath);
        String path = posix.join(rootPath, 'foo');
        provider.newFile(path, 'contents 1');
        return watchingFolder(rootPath, (changesReceived) {
          expect(changesReceived, hasLength(0));
          provider.modifyFile(path, 'contents 2');
          return delayed(() {
            expect(changesReceived, hasLength(1));
            expect(changesReceived[0].type, equals(ChangeType.MODIFY));
            expect(changesReceived[0].path, equals(path));
          });
        });
      });

      test('modify file in subdir', () {
        String rootPath = '/my/path';
        provider.newFolder(rootPath);
        String subdirPath = posix.join(rootPath, 'foo');
        provider.newFolder(subdirPath);
        String path = posix.join(rootPath, 'bar');
        provider.newFile(path, 'contents 1');
        return watchingFolder(rootPath, (changesReceived) {
          expect(changesReceived, hasLength(0));
          provider.modifyFile(path, 'contents 2');
          return delayed(() {
            expect(changesReceived, hasLength(1));
            expect(changesReceived[0].type, equals(ChangeType.MODIFY));
            expect(changesReceived[0].path, equals(path));
          });
        });
      });

      test('delete file', () {
        String rootPath = '/my/path';
        provider.newFolder(rootPath);
        String path = posix.join(rootPath, 'foo');
        provider.newFile(path, 'contents 1');
        return watchingFolder(rootPath, (changesReceived) {
          expect(changesReceived, hasLength(0));
          provider.deleteFile(path);
          return delayed(() {
            expect(changesReceived, hasLength(1));
            expect(changesReceived[0].type, equals(ChangeType.REMOVE));
            expect(changesReceived[0].path, equals(path));
          });
        });
      });
    });

    group('newFolder', () {
      test('empty path', () {
        expect(() {
          provider.newFolder('');
        }, throwsA(new isInstanceOf<ArgumentError>()));
      });

      test('not absolute', () {
        expect(() {
          provider.newFolder('not/absolute');
        }, throwsA(new isInstanceOf<ArgumentError>()));
      });

      group('already exists', () {
        test('as folder', () {
          Folder folder = provider.newFolder('/my/folder');
          Folder newFolder = provider.newFolder('/my/folder');
          expect(newFolder, folder);
        });

        test('as file', () {
          File file = provider.newFile('/my/file', 'qwerty');
          expect(() {
            provider.newFolder('/my/file');
          }, throwsA(new isInstanceOf<ArgumentError>()));
        });
      });
    });

    group('modifyFile', () {
      test('nonexistent', () {
        String path = '/my/file';
        expect(() {
          provider.modifyFile(path, 'contents');
        }, throwsA(new isInstanceOf<ArgumentError>()));
        Resource file = provider.getResource(path);
        expect(file, isNotNull);
        expect(file.exists, isFalse);
      });

      test('is folder', () {
        String path = '/my/file';
        provider.newFolder(path);
        expect(() {
          provider.modifyFile(path, 'contents');
        }, throwsA(new isInstanceOf<ArgumentError>()));
        expect(provider.getResource(path), new isInstanceOf<Folder>());
      });

      test('successful', () {
        String path = '/my/file';
        provider.newFile(path, 'contents 1');
        Resource file = provider.getResource(path);
        expect(file, new isInstanceOf<File>());
        Source source = (file as File).createSource(UriKind.FILE_URI);
        expect(source.contents.data, equals('contents 1'));
        provider.modifyFile(path, 'contents 2');
        expect(source.contents.data, equals('contents 2'));
      });
    });

    group('deleteFile', () {
      test('nonexistent', () {
        String path = '/my/file';
        expect(() {
          provider.deleteFile(path);
        }, throwsA(new isInstanceOf<ArgumentError>()));
        Resource file = provider.getResource(path);
        expect(file, isNotNull);
        expect(file.exists, isFalse);
      });

      test('is folder', () {
        String path = '/my/file';
        provider.newFolder(path);
        expect(() {
          provider.deleteFile(path);
        }, throwsA(new isInstanceOf<ArgumentError>()));
        expect(provider.getResource(path), new isInstanceOf<Folder>());
      });

      test('successful', () {
        String path = '/my/file';
        provider.newFile(path, 'contents');
        Resource file = provider.getResource(path);
        expect(file, new isInstanceOf<File>());
        expect(file.exists, isTrue);
        provider.deleteFile(path);
        expect(file.exists, isFalse);
      });
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
        expect(file.path, '/foo/bar/file.txt');
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

      test('parent', () {
        provider.newFile('/foo/bar/file.txt', 'content');
        File file = provider.getResource('/foo/bar/file.txt');
        Resource parent = file.parent;
        expect(parent, new isInstanceOf<Folder>());
        expect(parent.path, equals('/foo/bar'));
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

      test('parent', () {
        Resource parent1 = folder.parent;
        expect(parent1, new isInstanceOf<Folder>());
        expect(parent1.path, equals('/foo'));
        Resource parent2 = parent1.parent;
        expect(parent2, new isInstanceOf<Folder>());
        expect(parent2.path, equals('/'));
        expect(parent2.parent, isNull);
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
          expect(() {
            source.contents;
          }, throwsA(_isMemoryResourceException));
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

  group('ResourceUriResolver', testResourceResourceUriResolver);
}


void testResourceResourceUriResolver() {
  MemoryResourceProvider provider;
  ResourceUriResolver resolver;

  setUp(() {
    provider = new MemoryResourceProvider();
    resolver = new ResourceUriResolver(provider);
    provider.newFile('/test.dart', '');
    provider.newFolder('/folder');
  });

  group('fromEncoding', () {
    test('file', () {
      var uri = new Uri(path: '/test.dart');
      Source source = resolver.fromEncoding(UriKind.FILE_URI, uri);
      expect(source, isNotNull);
      expect(source.exists(), isTrue);
      expect(source.fullName, '/test.dart');
    });

    test('not a UriKind.FILE_URI', () {
      var uri = new Uri(path: '/test.dart');
      Source source = resolver.fromEncoding(UriKind.DART_URI, uri);
      expect(source, isNull);
    });
  });

  group('resolveAbsolute', () {
    test('file', () {
      var uri = new Uri(scheme: 'file', path: '/test.dart');
      Source source = resolver.resolveAbsolute(uri);
      expect(source, isNotNull);
      expect(source.exists(), isTrue);
      expect(source.fullName, '/test.dart');
    });

    test('folder', () {
      var uri = new Uri(scheme: 'file', path: '/folder');
      Source source = resolver.resolveAbsolute(uri);
      expect(source, isNull);
    });

    test('not a file URI', () {
      var uri = new Uri(scheme: 'https', path: '127.0.0.1/test.dart');
      Source source = resolver.resolveAbsolute(uri);
      expect(source, isNull);
    });
  });
}
