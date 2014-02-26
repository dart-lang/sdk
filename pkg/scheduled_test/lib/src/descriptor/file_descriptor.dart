// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.file;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

import '../../descriptor.dart';
import '../../scheduled_test.dart';
import '../utils.dart';

/// A descriptor describing a single file.
abstract class FileDescriptor extends Descriptor implements ReadableDescriptor {
  /// The contents of the file, in bytes.
  final List<int> contents;

  /// The contents of the file as a String. Assumes UTF-8 encoding.
  String get textContents => new String.fromCharCodes(contents);

  /// Creates a new text [FileDescriptor] with [name] that matches its String
  /// contents against [matcher]. If the file is created, it's considered to be
  /// empty.
  factory FileDescriptor.matcher(String name, Matcher matcher) =>
      new _MatcherFileDescriptor(name, matcher, isBinary: false);

  /// Creates a new binary [FileDescriptor] with [name] that matches its binary
  /// contents against [matcher]. If the file is created, it's considered to be
  /// empty.
  factory FileDescriptor.binaryMatcher(String name, Matcher matcher) =>
      new _MatcherFileDescriptor(name, matcher, isBinary: true);

  /// Creates a new binary [FileDescriptor] descriptor with [name] and
  /// [contents].
  factory FileDescriptor.binary(String name, List<int> contents) =>
      new _BinaryFileDescriptor(name, contents);

  /// Creates a new text [FileDescriptor] with [name] and [contents].
  factory FileDescriptor(String name, String contents) =>
      new _StringFileDescriptor(name, contents);

  FileDescriptor._(String name, this.contents)
      : super(name);

  Future create([String parent]) => schedule(() {
    if (parent == null) parent = defaultRoot;
    return Chain.track(new File(path.join(parent, name))
        .writeAsBytes(contents));
  }, "creating file '$name'");

  Future validate([String parent]) =>
    schedule(() => validateNow(parent), "validating file '$name'");

  Future validateNow([String parent]) {
    if (parent == null) parent = defaultRoot;
    var fullPath = path.join(parent, name);
    if (!new File(fullPath).existsSync()) {
      fail("File not found: '$fullPath'.");
    }

    return Chain.track(new File(fullPath).readAsBytes()).then(_validateNow);
  }

  // TODO(nweiz): rather than setting up an inheritance chain, just store a
  // Matcher for validation. This would require better error messages from the
  // matcher library, though.
  /// A function that throws an error if [binaryContents] doesn't match the
  /// expected contents of the descriptor.
  void _validateNow(List<int> binaryContents);

  Stream<List<int>> read() => new Future.value(contents).asStream();

  String describe() => name;
}

class _BinaryFileDescriptor extends FileDescriptor {
  _BinaryFileDescriptor(String name, List<int> contents)
      : super._(name, contents);

  Future _validateNow(List<int> actualContents) {
    if (orderedIterableEquals(contents, actualContents)) return null;
    // TODO(nweiz): show a hex dump here if the data is small enough.
    fail("File '$name' didn't contain the expected binary data.");
  }
}

class _StringFileDescriptor extends FileDescriptor {
  _StringFileDescriptor(String name, String contents)
      : super._(name, UTF8.encode(contents));

  Future _validateNow(List<int> actualContents) {
    if (orderedIterableEquals(contents, actualContents)) return null;
    throw _textMismatchMessage(textContents,
        new String.fromCharCodes(actualContents));
  }

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

class _MatcherFileDescriptor extends FileDescriptor {
  final Matcher _matcher;
  final bool _isBinary;

  _MatcherFileDescriptor(String name, this._matcher, {bool isBinary})
      : _isBinary = isBinary == true ? true : false,
        super._(name, <int>[]);

  void _validateNow(List<int> actualContents) =>
      expect(
          _isBinary ? actualContents : new String.fromCharCodes(actualContents),
          _matcher);
}
