// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.file;

import 'dart:async';
import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:utf';

import '../../../../../pkg/pathos/lib/path.dart' as path;

import '../../descriptor.dart' as descriptor;
import '../../scheduled_test.dart';
import '../utils.dart';
import 'utils.dart';

/// A descriptor describing a single file.
class File extends descriptor.Entry {
  /// Whether this descriptor describes a binary file. This is only used when
  /// displaying error messages.
  final bool isBinary;

  /// The contents of the file, in bytes.
  final List<int> contents;

  /// The contents of the file as a String. Assumes UTF-8 encoding.
  String get textContents => new String.fromCharCodes(contents);

  File.binary(Pattern name, List<int> contents)
      : this._(name, contents, true);

  File(Pattern name, String contents)
      : this._(name, encodeUtf8(contents), false);

  File._(Pattern name, this.contents, this.isBinary)
      : super(name);

  Future create([String parent]) => schedule(() {
    if (parent == null) parent = descriptor.defaultRoot;
    return new io.File(path.join(parent, stringName)).writeAsBytes(contents);
  }, 'creating file $nameDescription');

  Future validate([String parent]) => schedule(() {
    if (parent == null) parent = descriptor.defaultRoot;
    var fullPath = entryMatchingPattern('File', parent, name);
    return new io.File(fullPath).readAsBytes()
        .then((actualContents) {
      if (orderedIterableEquals(contents, actualContents)) return;
      if (isBinary) {
        // TODO(nweiz): show a hex dump here if the data is small enough.
        throw "File $nameDescription didn't contain the expected binary "
            "data.";
      }
      var description = nameDescription;
      if (name is! String) {
        description = "'${path.basename(fullPath)}' (matching $description)";
      }
      throw _textMismatchMessage(description, textContents,
          new String.fromCharCodes(actualContents));;
    });
  }, 'validating file $nameDescription');

  Stream<List<int>> read() => new Future.immediate(contents).asStream();

  String describe() {
    if (name is String) return name;
    return 'file matching $nameDescription';
  }
}

String _textMismatchMessage(String description, String expected,
    String actual) {
  final expectedLines = expected.split('\n');
  final actualLines = actual.split('\n');

  var results = [];

  // Compare them line by line to see which ones match.
  var length = math.max(expectedLines.length, actualLines.length);
  for (var i = 0; i < length; i++) {
    if (i >= actualLines.length) {
      // Missing output.
      results.add('? ${expectedLines[i]}');
    } else if (i >= expectedLines.length) {
      // Unexpected extra output.
      results.add('X ${actualLines[i]}');
    } else {
      var expectedLine = expectedLines[i];
      var actualLine = actualLines[i];

      if (expectedLine != actualLine) {
        // Mismatched lines.
        results.add('X $actualLine');
      } else {
        // Matched lines.
        results.add('| $actualLine');
      }
    }
  }

  return "File $description should contain:\n"
    "${prefixLines(expected)}\n"
    "but actually contained:\n"
    "${results.join('\n')}";
}
