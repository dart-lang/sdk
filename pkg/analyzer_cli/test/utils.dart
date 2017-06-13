// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.utils;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as pathos;

/// Gets the test directory in a way that works with package:test
/// See <https://github.com/dart-lang/test/issues/110> for more info.
final String testDirectory = pathos.dirname(
    pathos.fromUri((reflectClass(_TestUtils).owner as LibraryMirror).uri));

/// Returns the string representation of the [AnalyzerErrorGroup] thrown when
/// parsing [contents] as a Dart file. If [contents] doesn't throw any errors,
/// this will return null.
///
/// This replaces the filename in the error string with its basename, since the
/// full path will vary from machine to machine. It also replaces the exception
/// message with "..." to decouple these tests from the specific exception
/// messages.
String errorsForFile(String contents) {
  return withTempDir((temp) {
    var path = pathos.join(temp, 'test.dart');
    new File(path).writeAsStringSync(contents);
    try {
      parseDartFile(path);
    } on AnalyzerErrorGroup catch (e) {
      return e.toString().replaceAllMapped(
          new RegExp(r"^(Error on line \d+ of )((?:[A-Z]+:)?[^:]+): .*$",
              multiLine: true),
          (match) => match[1] + pathos.basename(match[2]) + ': ...');
    }
    return null;
  });
}

/// Recursively copy the specified [src] directory (or file)
/// to the specified destination path.
Future<Null> recursiveCopy(FileSystemEntity src, String dstPath) async {
  if (src is Directory) {
    await (new Directory(dstPath)).create(recursive: true);
    for (FileSystemEntity entity in src.listSync()) {
      await recursiveCopy(
          entity, pathos.join(dstPath, pathos.basename(entity.path)));
    }
  } else if (src is File) {
    await src.copy(dstPath);
  }
}

/// Creates a temporary directory and passes its path to [fn]. Once [fn]
/// completes, the temporary directory and all its contents will be deleted.
///
/// Returns the return value of [fn].
dynamic withTempDir(fn(String path)) {
  var tempDir = Directory.systemTemp.createTempSync('analyzer_').path;
  try {
    return fn(tempDir);
  } finally {
    new Directory(tempDir).deleteSync(recursive: true);
  }
}

/// Creates a temporary directory and passes its path to [fn]. Once [fn]
/// completes, the temporary directory and all its contents will be deleted.
///
/// Returns the return value of [fn].
Future<dynamic> withTempDirAsync(Future<dynamic> fn(String path)) async {
  var tempDir = (await Directory.systemTemp.createTemp('analyzer_')).path;
  try {
    return await fn(tempDir);
  } finally {
    await new Directory(tempDir).delete(recursive: true);
  }
}

class _TestUtils {}
