// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as pathos;

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

/// Creates a temporary directory and passes its path to [fn]. Once [fn]
/// completes, the temporary directory and all its contents will be deleted.
///
/// Returns the return value of [fn].
dynamic withTempDir(fn(String path)) {
  var tempDir =
      Directory.systemTemp.createTempSync('analyzer_').path;
  try {
    return fn(tempDir);
  } finally {
    new Directory(tempDir).deleteSync(recursive: true);
  }
}
