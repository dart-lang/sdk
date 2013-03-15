// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.file;

import 'dart:async';
import 'dart:io' as io;

import '../../../../../pkg/pathos/lib/path.dart' as path;

import '../../descriptor.dart' as descriptor;
import '../../scheduled_test.dart';
import '../utils.dart';
import 'utils.dart';

/// A path builder to ensure that [load] uses POSIX paths.
final path.Builder _path = new path.Builder(style: path.Style.posix);

/// A descriptor describing a directory containing multiple files.
class Directory extends descriptor.Entry {
  /// The entries contained within this directory.
  final Iterable<descriptor.Entry> contents;

  Directory(Pattern name, this.contents)
      : super(name);

  Future create([String parent]) => schedule(() {
    if (parent == null) parent = descriptor.defaultRoot;
    var fullPath = path.join(parent, stringName);
    return new io.Directory(fullPath).create(recursive: true).then((_) {
      return Future.wait(
          contents.map((entry) => entry.create(fullPath)).toList());
    });
  }, 'creating directory:\n${describe()}');

  Future validate([String parent]) => schedule(() {
    if (parent == null) parent = descriptor.defaultRoot;
    var fullPath = entryMatchingPattern('Directory', parent, name);
    return Future.wait(
        contents.map((entry) => entry.validate(fullPath)).toList());
  }, 'validating directory:\n${describe()}');

  Stream<List<int>> load(String pathToLoad) {
    return futureStream(new Future.immediate(null).then((_) {
      if (_path.isAbsolute(pathToLoad)) {
        throw "Can't load absolute path '$pathToLoad'.";
      }

      var split = _path.split(_path.normalize(pathToLoad));
      if (split.isEmpty || split.first == '.' || split.first == '..') {
        throw "Can't load '$pathToLoad' from within $nameDescription.";
      }

      var matchingEntries = contents.where((entry) =>
          entry.stringName == split.first).toList();

      if (matchingEntries.length == 0) {
        throw "Couldn't find an entry named '${split.first}' within "
            "$nameDescription.";
      } else if (matchingEntries.length > 1) {
        throw "Found multiple entries named '${split.first}' within "
            "$nameDescription.";
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

  Stream<List<int>> read() => errorStream("Can't read the contents of "
      "$nameDescription: is a directory.");

  String describe() {
    var description = name;
    if (name is! String) description = 'directory matching $nameDescription';
    if (contents.isEmpty) return description;

    var buffer = new StringBuffer();
    buffer.writeln(description);
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
