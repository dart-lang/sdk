// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:tar/tar.dart';

import '../../worker_harness.dart';

void main() {
  group('writeFileFromText / readFileAsText', () {
    testDartWorkspace('can write and read a file', (ws) async {
      await ws.writeFileFromText('test.txt', 'hello world');
      final content = await ws.readFileAsText('test.txt');
      check(content).equals('hello world');
    });

    testDartWorkspace('can write to a subfolder', (ws) async {
      await ws.writeFileFromText('sub/test.txt', 'hello sub');
      final content = await ws.readFileAsText('sub/test.txt');
      check(content).equals('hello sub');
    });

    testDartWorkspace('recursively creates parent directories', (ws) async {
      await ws.writeFileFromText('a/b/c/test.txt', 'deep file');
      final content = await ws.readFileAsText('a/b/c/test.txt');
      check(content).equals('deep file');
    });

    testDartWorkspace('throws if reading non-existent file', (ws) async {
      await check(
        ws.readFileAsText('notfound.txt'),
      ).throws<FileNotFoundException>();
    });
  });

  group('writeFileFromBytes / readFileAsBytes', () {
    testDartWorkspace('can write and read bytes', (ws) async {
      final bytes = Uint8List.fromList(utf8.encode('hello bytes'));
      await ws.writeFileFromBytes('test.bin', bytes);
      final resultBytes = await ws.readFileAsBytes('test.bin');
      check(resultBytes).deepEquals(bytes);
      check(utf8.decode(resultBytes)).equals('hello bytes');
    });

    testDartWorkspace('recursively creates parent directories', (ws) async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      await ws.writeFileFromBytes('deep/path/bytes.bin', bytes);
      final resultBytes = await ws.readFileAsBytes('deep/path/bytes.bin');
      check(resultBytes).deepEquals(bytes);
    });
  });

  group('createFolder / listDirectory', () {
    testDartWorkspace('can create and list folders', (ws) async {
      await ws.createFolder('myfolder');
      await ws.writeFileFromText('myfolder/file1.txt', 'one');
      await ws.writeFileFromText('myfolder/file2.txt', 'two');

      final entries = await ws.listDirectory(uri: 'myfolder');
      check(entries).length.equals(2);
      check(
        entries.any((e) => e.path == 'file1.txt' && e.type == 'file'),
      ).isTrue();
      check(
        entries.any((e) => e.path == 'file2.txt' && e.type == 'file'),
      ).isTrue();
    });

    testDartWorkspace('can list recursively', (ws) async {
      await ws.writeFileFromText('a/b/c.txt', 'deep');
      final entries = await ws.listDirectory(uri: 'a', recursive: true);
      check(entries).length.equals(2); // b and b/c.txt
      check(entries.any((e) => e.path == 'b' && e.type == 'folder')).isTrue();
      check(
        entries.any((e) => e.path == 'b/c.txt' && e.type == 'file'),
      ).isTrue();
    });

    testDartWorkspace('can ignore hidden files', (ws) async {
      await ws.writeFileFromText('.hidden', 'secret');
      await ws.writeFileFromText('visible', 'hello');

      final all = await ws.listDirectory(uri: '.', ignoreHidden: false);
      check(all.any((e) => e.path == '.hidden')).isTrue();

      final visible = await ws.listDirectory(uri: '.', ignoreHidden: true);
      check(visible.any((e) => e.path == '.hidden')).isFalse();
      check(visible.any((e) => e.path == 'visible')).isTrue();
    });

    testDartWorkspace('can create folders recursively', (ws) async {
      await ws.createFolder('deep/folder/structure');
      final s = await ws.stat('deep/folder/structure');
      check(s.type).equals('folder');
    });
  });

  group('deleteFileSystemEntity', () {
    testDartWorkspace('can delete a file', (ws) async {
      await ws.writeFileFromText('test.txt', 'to be deleted');
      await ws.deleteFileSystemEntity('test.txt');
      await check(
        ws.readFileAsText('test.txt'),
      ).throws<FileNotFoundException>();
    });

    testDartWorkspace('can delete a folder', (ws) async {
      await ws.createFolder('myfolder');
      await ws.writeFileFromText('myfolder/file.txt', 'inside');
      await ws.deleteFileSystemEntity('myfolder');
      await check(
        ws.listDirectory(uri: 'myfolder'),
      ).throws<FileNotFoundException>();
    });
  });

  group('stat', () {
    testDartWorkspace('stat a file', (ws) async {
      await ws.writeFileFromText('test.txt', 'hello world');
      final s = await ws.stat('test.txt');
      check(s.type).equals('file');
      check(s.size).equals(11);
    });

    testDartWorkspace('stat a folder', (ws) async {
      await ws.createFolder('myfolder');
      final s = await ws.stat('myfolder');
      check(s.type).equals('folder');
      check(s.size).isNull();
    });

    testDartWorkspace('stat non-existent', (ws) async {
      await check(ws.stat('notfound.txt')).throws<FileNotFoundException>();
    });
  });

  group('fileExist / folderExist', () {
    testDartWorkspace('fileExist returns true for file', (ws) async {
      await ws.writeFileFromText('test.txt', 'hello');
      check(await ws.fileExist('test.txt')).isTrue();
      check(await ws.folderExist('test.txt')).isFalse();
    });

    testDartWorkspace('folderExist returns true for folder', (ws) async {
      await ws.createFolder('myfolder');
      check(await ws.folderExist('myfolder')).isTrue();
      check(await ws.fileExist('myfolder')).isFalse();
    });

    testDartWorkspace('both return false for non-existent', (ws) async {
      check(await ws.fileExist('notfound')).isFalse();
      check(await ws.folderExist('notfound')).isFalse();
    });

    testDartWorkspace('fileExist returns true for nested file', (ws) async {
      await ws.writeFileFromText('a/b/c.txt', 'hello');
      check(await ws.fileExist('a/b/c.txt')).isTrue();
      check(await ws.folderExist('a/b')).isTrue();
    });
  });

  group('importTarArchive / exportTarArchive', () {
    testDartWorkspace('export a directory as tar', (ws) async {
      await ws.writeFileFromText('dir/file1.txt', 'content1');
      await ws.writeFileFromText('dir/sub/file2.txt', 'content2');

      final tarBytes = await ws.exportTarArchive('dir');

      final reader = TarReader(Stream.value(tarBytes));
      final files = <String, String>{};
      while (await reader.moveNext()) {
        final entry = reader.current;
        if (entry.header.typeFlag == TypeFlag.reg ||
            entry.header.typeFlag == TypeFlag.regA) {
          final b = BytesBuilder();
          await entry.contents.forEach(b.add);
          files[entry.name] = utf8.decode(b.toBytes());
        }
      }

      check(files).length.equals(2);
      check(files['file1.txt']).equals('content1');
      check(files['sub/file2.txt']).equals('content2');
    });

    testDartWorkspace('import a tar into a directory', (ws) async {
      final tarBytes = await createTarBytes([
        tarFile('file3.txt', 'content3'),
        tarFile('nested/file4.txt', 'content4'),
      ]);

      await ws.importTarArchive('imported', tarBytes);

      check(await ws.readFileAsText('imported/file3.txt')).equals('content3');
      check(
        await ws.readFileAsText('imported/nested/file4.txt'),
      ).equals('content4');
    });

    testDartWorkspace('export directory not found', (ws) async {
      await check(ws.exportTarArchive('nonexistent')).throws();
    });

    testDartWorkspace('import creates destination', (ws) async {
      final tarBytes = await createTarBytes([tarFile('f.txt', 'c')]);

      await ws.importTarArchive('new_dir', tarBytes);
      check(await ws.readFileAsText('new_dir/f.txt')).equals('c');
    });

    testDartWorkspace('import tar without directory entries', (ws) async {
      // Add a deep file without adding the parent 'a/' or 'a/b/' entries
      final tarBytes = await createTarBytes([
        tarFile('a/b/c.txt', 'deep content'),
      ]);

      await ws.importTarArchive('deep_import', tarBytes);

      check(
        await ws.readFileAsText('deep_import/a/b/c.txt'),
      ).equals('deep content');
    });
  });
}

Future<Uint8List> createTarBytes(List<TarEntry> entries) async =>
    await collectBytes(Stream.fromIterable(entries).transform(tarWriter));

TarEntry tarFile(String name, String contents) =>
    TarEntry.data(TarHeader(name: name, mode: 420), utf8.encode(contents));
