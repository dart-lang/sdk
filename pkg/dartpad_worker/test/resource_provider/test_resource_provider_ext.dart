// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:async/async.dart';
import 'package:dartpad_worker/src/resource_provider/resource_provider_ext.dart';
import 'package:tar/tar.dart';
import 'package:test/test.dart';

import '../checks_ext.dart';

void main() {
  late MemoryResourceProvider provider;
  late Folder target;

  setUp(() {
    provider = MemoryResourceProvider();
    target = provider.getFolder('/extract')..create();
  });

  group('FolderExt.createRecursively', () {
    test('creates nested folders', () {
      final folder = target.getFolder('a/b/c');
      check(folder).doesNotExist;

      folder.createRecursively();

      check(folder).exists;
      check(target).folder('a/b').exists;
      check(target).folder('a').exists;
    });

    test('does nothing if folder exists', () {
      final folder = target.getFolder('a')..create();
      check(folder).exists;

      folder.createRecursively();

      check(folder).exists;
    });
  });

  group('FolderExt.extractTarStream', () {
    Stream<List<int>> tarStream(List<TarEntry> entries) =>
        Stream.fromIterable(entries).transform(tarWriter);

    TarEntry tarFile(String name, String contents) =>
        TarEntry.data(TarHeader(name: name, mode: 420), utf8.encode(contents));

    TarEntry tarFolder(String name) => TarEntry.data(
      TarHeader(
        name: name.endsWith('/') ? name : '$name/',
        typeFlag: TypeFlag.dir,
        mode: 493,
      ),
      const [],
    );

    test('extracts files and directories', () async {
      await target.extractTarStream(
        tarStream([
          tarFile('file.txt', 'content'),
          tarFolder('dir'),
          tarFile('dir/nested.txt', 'nested'),
        ]),
      );

      check(target).file('file.txt').contents.equals('content');
      check(target).folder('dir').exists;
      check(target).file('dir/nested.txt').contents.equals('nested');
    });

    test('adversarial: prevents escaping target folder', () async {
      await target.extractTarStream(
        tarStream([
          tarFile('../escaped.txt', 'malicious'),
          tarFile('/absolute.txt', 'malicious'),
          tarFile('subdir/../../double_escaped.txt', 'malicious'),
        ]),
      );

      // Should not exist outside targetFolder
      check(provider.getFile('/escaped.txt')).doesNotExist;
      check(provider.getFile('/absolute.txt')).doesNotExist;
      check(provider.getFile('/double_escaped.txt')).doesNotExist;

      // Should be neutralized and extracted inside targetFolder
      check(target).file('escaped.txt').contents.equals('malicious');
      check(target).file('absolute.txt').contents.equals('malicious');
      check(target).file('double_escaped.txt').contents.equals('malicious');
    });

    test('handles "." and empty names gracefully', () async {
      await target.extractTarStream(
        tarStream([
          tarFolder('.'),
          tarFolder('./'),
          tarFolder(''),
          tarFile('valid.txt', 'valid'),
        ]),
      );

      check(target).file('valid.txt').contents.equals('valid');
    });
  });

  group('FolderExt.createTarStream', () {
    test('creates a tar stream from folder contents', () async {
      target.getFile('a.txt').writeAsStringSync('a');
      target.getFolder('sub').create();
      target.getFile('sub/b.txt').writeAsStringSync('b');

      final reader = TarReader(target.createTarStream());

      final entries = <String, String>{};
      while (await reader.moveNext()) {
        final entry = reader.current;
        if (entry.header.typeFlag == TypeFlag.dir) {
          entries[entry.header.name] = 'DIR';
        } else {
          entries[entry.header.name] = utf8.decode(
            await collectBytes(entry.contents),
          );
        }
      }

      check(entries).has((e) => e.length, 'length').equals(3);
      check(entries).containsKey('a.txt');
      check(entries['a.txt']).equals('a');
      check(entries).containsKey('sub/');
      check(entries['sub/']).equals('DIR');
      check(entries).containsKey('sub/b.txt');
      check(entries['sub/b.txt']).equals('b');
    });
  });
}
