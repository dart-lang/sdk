// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.directory;

import 'dart:async';
import 'dart:io';

import 'package:pathos/path.dart' as path;

import '../../descriptor.dart';
import '../../scheduled_test.dart';
import '../utils.dart';

/// A path builder to ensure that [load] uses POSIX paths.
final path.Builder _path = new path.Builder(style: path.Style.posix);

/// A descriptor describing a directory containing multiple files.
class DirectoryDescriptor extends Descriptor {
  /// The entries contained within this directory. This is intentionally
  /// mutable.
  final List<Descriptor> contents;

  DirectoryDescriptor(String name, Iterable<Descriptor> contents)
      : super(name),
        contents = contents.toList();

  Future create([String parent]) => schedule(() {
    if (parent == null) parent = defaultRoot;
    var fullPath = path.join(parent, name);
    return new Directory(fullPath).create(recursive: true).then((_) {
      return Future.wait(
          contents.map((entry) => entry.create(fullPath)).toList());
    });
  }, 'creating directory:\n${describe()}');

  Future validate([String parent]) => schedule(() => validateNow(parent),
      'validating directory:\n${describe()}');

  Future validateNow([String parent]) {
    if (parent == null) parent = defaultRoot;
    var fullPath = path.join(parent, name);
    if (!new Directory(fullPath).existsSync()) {
      throw "Directory not found: '$fullPath'.";
    }

    return Future.wait(contents.map((entry) {
      return new Future.sync(() => entry.validateNow(fullPath))
          .then((_) => null)
          .catchError((e) => e);
    })).then((results) {
      var errors = results.where((e) => e != null);
      if (errors.isEmpty) return;
      throw _DirectoryValidationError.merge(errors);
    });
  }

  Stream<List<int>> load(String pathToLoad) {
    return futureStream(new Future.value().then((_) {
      if (_path.isAbsolute(pathToLoad)) {
        throw "Can't load absolute path '$pathToLoad'.";
      }

      var split = _path.split(_path.normalize(pathToLoad));
      if (split.isEmpty || split.first == '.' || split.first == '..') {
        throw "Can't load '$pathToLoad' from within '$name'.";
      }

      var matchingEntries = contents.where((entry) =>
          entry.name == split.first).toList();

      if (matchingEntries.length == 0) {
        throw "Couldn't find an entry named '${split.first}' within '$name'.";
      } else if (matchingEntries.length > 1) {
        throw "Found multiple entries named '${split.first}' within '$name'.";
      } else {
        var remainingPath = split.sublist(1);
        if (remainingPath.isEmpty) {
          return matchingEntries.first.read();
        } else {
          return matchingEntries.first.load(_path.joinAll(remainingPath));
        }
      }
    }));
  }

  Stream<List<int>> read() => errorStream("Can't read the contents of '$name': "
      "is a directory.");

  String describe() {
    if (contents.isEmpty) return name;

    var buffer = new StringBuffer();
    buffer.writeln(name);
    for (var entry in contents.take(contents.length - 1)) {
      var entryString = prefixLines(entry.describe(), prefix: '|   ')
          .replaceFirst('|   ', '|-- ');
      buffer.writeln(entryString);
    }

    var lastEntryString = prefixLines(contents.last.describe(), prefix: '    ')
        .replaceFirst('    ', "'-- ");
    buffer.write(lastEntryString);
    return buffer.toString();
  }
}

/// A class for formatting errors thrown by [DirectoryDescriptor].
class _DirectoryValidationError {
  final Iterable<String> errors;

  /// Flatten nested [_DirectoryValidationError]s in [errors] to create a single
  /// list of errors.
  static _DirectoryValidationError merge(Iterable errors) {
    return new _DirectoryValidationError(errors.expand((error) {
      if (error is _DirectoryValidationError) return error.errors;
      return [error];
    }));
  }

  _DirectoryValidationError(Iterable errors)
      : errors = errors.map((e) => e.toString()).toList();

  String toString() {
    if (errors.length == 1) return errors.single;
    return errors.map((e) => prefixLines(e, prefix: '  ', firstPrefix: '* '))
        .join('\n');
  }
}
