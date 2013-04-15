// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.file;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:utf';

import 'package:pathos/path.dart' as path;

import '../../descriptor.dart';
import '../../scheduled_test.dart';
import '../utils.dart';

/// A descriptor describing a single file.
class FileDescriptor extends Descriptor {
  /// Whether this descriptor describes a binary file. This is only used when
  /// displaying error messages.
  final bool isBinary;

  /// The contents of the file, in bytes.
  final List<int> contents;

  /// The contents of the file as a String. Assumes UTF-8 encoding.
  String get textContents => new String.fromCharCodes(contents);

  FileDescriptor.binary(String name, List<int> contents)
      : this._(name, contents, true);

  FileDescriptor(String name, String contents)
      : this._(name, encodeUtf8(contents), false);

  FileDescriptor._(String name, this.contents, this.isBinary)
      : super(name);

  Future create([String parent]) => schedule(() {
    if (parent == null) parent = defaultRoot;
    return new File(path.join(parent, name)).writeAsBytes(contents);
  }, "creating file '$name'");

  Future validate([String parent]) =>
    schedule(() => validateNow(parent), "validating file '$name'");

  Future validateNow([String parent]) {
    if (parent == null) parent = defaultRoot;
    var fullPath = path.join(parent, name);
    if (!new File(fullPath).existsSync()) {
      throw "File not found: '$fullPath'.";
    }

    return new File(fullPath).readAsBytes()
        .then((actualContents) {
      if (orderedIterableEquals(contents, actualContents)) return;
      if (isBinary) {
        // TODO(nweiz): show a hex dump here if the data is small enough.
        throw "File '$name' didn't contain the expected binary data.";
      }
      throw _textMismatchMessage(textContents,
          new String.fromCharCodes(actualContents));
    });
  }

  Stream<List<int>> read() => new Future.value(contents).asStream();

  String describe() => name;

  String _textMismatchMessage(String expected, String actual) {
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

    return "File '$name' should contain:\n"
        "${prefixLines(expected)}\n"
        "but actually contained:\n"
        "${results.join('\n')}";
  }
}
