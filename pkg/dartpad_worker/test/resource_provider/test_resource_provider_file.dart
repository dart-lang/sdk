// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:dartpad_worker/src/resource_provider/resource_provider_file.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late MemoryResourceProvider rp;
  late FileSystem fs;

  setUp(() {
    rp = MemoryResourceProvider(context: p.posix);
    fs = resourceProviderAsFileFileSystem(rp);
  });

  test('file() returns a File that works with ResourceProvider', () {
    final file = fs.file('/test.txt');
    file.writeAsStringSync('hello world');
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), 'hello world');

    expect(rp.getFile('/test.txt').exists, isTrue);
    expect(rp.getFile('/test.txt').readAsStringSync(), 'hello world');
  });

  test('directory() returns a Directory that works with ResourceProvider', () {
    final dir = fs.directory('/foo/bar');
    dir.createSync(recursive: true);
    expect(dir.existsSync(), isTrue);

    expect(rp.getFolder('/foo/bar').exists, isTrue);
  });

  test('stat() returns correct information', () {
    final file = fs.file('/stat.txt');
    file.writeAsStringSync('content');
    final stat = file.statSync();
    expect(stat.type, io.FileSystemEntityType.file);
    expect(stat.size, 7);
  });

  test('listSync() lists files', () {
    fs.directory('/dir').createSync();
    fs.file('/dir/a.txt').writeAsStringSync('a');
    fs.file('/dir/b.txt').writeAsStringSync('b');

    final entries = fs.directory('/dir').listSync();
    expect(entries.length, 2);
    expect(entries.any((e) => e.path.endsWith('a.txt')), isTrue);
    expect(entries.any((e) => e.path.endsWith('b.txt')), isTrue);
  });

  test('identicalSync() works', () {
    fs.file('/a.txt').createSync();
    expect(fs.identicalSync('/a.txt', '/a.txt'), isTrue);
    expect(fs.identicalSync('/a.txt', '/b.txt'), isFalse);
  });

  test('typeSync() works', () {
    fs.file('/file.txt').createSync();
    fs.directory('/dir').createSync();
    expect(fs.typeSync('/file.txt'), io.FileSystemEntityType.file);
    expect(fs.typeSync('/dir'), io.FileSystemEntityType.directory);
    expect(fs.typeSync('/none'), io.FileSystemEntityType.notFound);
  });

  test('RandomAccessFile works', () async {
    final file = fs.file('/raf.txt');
    final raf = file.openSync(mode: io.FileMode.write);
    raf.writeStringSync('hello');
    raf.setPositionSync(0);
    final bytes = await raf.read(5);
    expect(bytes, [104, 101, 108, 108, 111]); // 'hello'
    raf.closeSync();

    expect(file.readAsStringSync(), 'hello');
  });

  test('Directory rename works', () {
    final dir = fs.directory('/old');
    dir.createSync();
    fs.file('/old/file.txt').writeAsStringSync('content');

    dir.renameSync('/new');

    expect(fs.directory('/old').existsSync(), isFalse);
    expect(fs.directory('/new').existsSync(), isTrue);
    expect(fs.file('/new/file.txt').readAsStringSync(), 'content');
  });

  test('parent property works', () {
    final file = fs.file('/foo/bar/test.txt');
    expect(file.parent.path, '/foo/bar');
    expect(file.parent.parent.path, '/foo');
  });

  test('existsSync() respects entity type', () {
    fs.directory('/test_dir').createSync();
    fs.file('/test_dir/file.txt').writeAsStringSync('content');
    fs.link('/test_link').createSync('/test_dir');

    // Directory
    expect(fs.directory('/test_dir').existsSync(), isTrue);
    expect(fs.file('/test_dir').existsSync(), isFalse);
    expect(fs.link('/test_dir').existsSync(), isFalse);

    // File
    expect(fs.file('/test_dir/file.txt').existsSync(), isTrue);
    expect(fs.directory('/test_dir/file.txt').existsSync(), isFalse);
    expect(fs.link('/test_dir/file.txt').existsSync(), isFalse);

    // Link
    expect(fs.link('/test_link').existsSync(), isTrue);
    // link points to a directory
    expect(fs.directory('/test_link').existsSync(), isTrue);
    // link points to a directory, not a file
    expect(fs.file('/test_link').existsSync(), isFalse);
  });

  test('typeSync() respects followLinks argument', () {
    fs.directory('/test_dir2').createSync();
    fs.file('/test_dir2/file.txt').writeAsStringSync('content');
    fs.link('/test_link2').createSync('/test_dir2');
    fs.link('/test_link3').createSync('/test_dir2/file.txt');

    // Directory link
    expect(fs.typeSync('/test_link2'), io.FileSystemEntityType.directory);
    expect(
      fs.typeSync('/test_link2', followLinks: false),
      io.FileSystemEntityType.link,
    );

    // File link
    expect(fs.typeSync('/test_link3'), io.FileSystemEntityType.file);
    expect(
      fs.typeSync('/test_link3', followLinks: false),
      io.FileSystemEntityType.link,
    );
  });
}
