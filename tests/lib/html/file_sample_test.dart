// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library file_sample;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_helper.dart';
import 'package:expect/minitest.dart';

// Expected output from all functions, asynchronous, and event routines.
const String log_results = 'test-first\n' +
    'acquire START\n' +
    'acquire CALLBACK START\n' +
    'acquire CALLBACK END\n' +
    'first START\n' +
    'first END\n' +
    'test-second\n' +
    'second START\n' +
    'second END\n' +
    'reader onLoadEnd event\n' +
    'file content = XYZZY Output\n';

// Simple logger to record all output.
class Logger {
  StringBuffer _log = new StringBuffer();

  void log(String message) {
    _log.writeln(message);
  }

  String get contents => _log.toString();
}

Logger testLog = new Logger();

Future<FileSystem>? _fileSystem;

late DirectoryEntry _myDirectory;

Future<FileSystem> get fileSystem async {
  if (_fileSystem != null) return _fileSystem!;

  testLog.log('acquire START');
  _fileSystem = window.requestFileSystem(100);

  var fs = await _fileSystem!;
  testLog.log('acquire CALLBACK START');
  expect(fs.runtimeType, FileSystem);
  expect(fs.root.runtimeType, DirectoryEntry);
  testLog.log('acquire CALLBACK END');

  return _fileSystem!;
}

Future<FileEntry> createFile() async {
  var fs = await fileSystem;

  _myDirectory =
      await fs.root!.createDirectory('my_directory') as DirectoryEntry;

  FileEntry fileEntry = await _myDirectory.createFile('log.txt') as FileEntry;

  expect(fileEntry.isFile, true);
  expect(fileEntry.name, 'log.txt');
  expect(fileEntry.fullPath, '/my_directory/log.txt');

  FileWriter writer = await fileEntry.createWriter();

  Blob blob = new Blob(['XYZZY Output'], 'text/plain');

  writer.write(blob);

  var reader = new FileReader();

  var completer = new Completer<String>();

  reader.onLoadEnd.listen((event) {
    testLog.log('reader onLoadEnd event');
    dynamic target = event.currentTarget;
    testLog.log('file content = ${target.result}');
    expect(target.result, 'XYZZY Output');

    completer.complete(target.result);
  });

  Blob readBlob = await fileEntry.file();

  reader.readAsText(readBlob);

  // Wait until onLoadEnd if fired.
  await completer.future;

  return new Future<FileEntry>.value(fileEntry);
}

Future<List<Entry>> readEntries(DirectoryEntry directory) async {
  DirectoryReader reader = directory.createReader();
  List<Entry> entries = await reader.readEntries();
  return entries;
}

Future testFileSystemRequest() async {
  testLog.log('test-first');
  var fs = await fileSystem;
  testLog.log('first START');
  expect(fs.runtimeType, FileSystem);
  expect(fs.root.runtimeType, DirectoryEntry);
  testLog.log('first END');
}

Future testFileSystemRequestCreateRW() async {
  testLog.log('test-second');
  var fs = await fileSystem;
  testLog.log('second START');
  expect(fs.runtimeType, FileSystem);
  expect(fs.root.runtimeType, DirectoryEntry);
  testLog.log('second END');

  FileEntry fileEntry = await createFile();
  expect(fileEntry.name, 'log.txt');

  List<Entry> entries = await readEntries(fs.root!);
  expect(entries.length > 0, true);
  expect(entries[0].isDirectory, true);
  expect(entries[0].name, 'my_directory');

  List<Entry> myEntries = await readEntries(_myDirectory);
  expect(myEntries.length, 1);
  expect(myEntries[0].isFile, true);
  expect(myEntries[0].name, 'log.txt');

  // Validate every function, async and event mechanism successfully ran.
  expect(testLog.contents, log_results);
}

main() {
  asyncTest(() async {
    await testFileSystemRequest();
    await testFileSystemRequestCreateRW();
  });
}
