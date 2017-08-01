// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:status_file/status_file.dart';

import 'io.dart';
import 'log.dart';

// TODO(rnystrom): This file is kind of a hack. The problem is that a parsed
// StatusFile doesn't contain all of the original information in the source
// text. Comments and whitespace are lost. That means a StatusFile itself
// couldn't be modified and saved back to disc.
//
// Instead, this wraps a StatusFile and also lets you modify entire lines in
// it, including their comments. Ideally, StatusFile would include parsed
// comments and we would canonicalize other whitespace so that you could
// modify a StatusFile object then save it back to disc.
class EditableStatusFile {
  final String path;

  StatusFile _statusFile;
  StatusFile get statusFile {
    if (_statusFile == null) {
      _statusFile = new StatusFile.read(path);
    }

    return _statusFile;
  }

  List<String> _lines;

  EditableStatusFile(this.path);

  /// Gets the line at the given one-based index.
  String lineAt(int line) {
    _ensureLines();
    return _lines[line - 1];
  }

  /// Delete the numbered [lines] from the file.
  void delete(List<int> lines) {
    if (lines.isEmpty) return;

    if (dryRun) {
      print("Delete lines ${lines.join(', ')} from $path.");
      return;
    }

    _ensureLines();

    var deleted = 0;
    for (var line in lines) {
      // Adjust index because previous lines have already been removed, shifting
      // the subsequent line numbers.
      _lines.removeAt(line - deleted);
      deleted++;
    }

    _save();
  }

  /// Insert [entries] at [line] in the file.
  void insert(int line, List<String> entries) {
    if (dryRun) {
      print("Insert ${bold(path)}, insert at line $line:");
      entries.forEach(print);
      return;
    }

    _ensureLines();
    _lines.insertAll(line, entries);
    _save();
  }

  /// Adds [header] followed by [entries] to the end of the file.
  void append(String header, List<String> entries) {
    if (dryRun) {
      print("To ${bold(path)}, append:");
      print(header);
      entries.forEach(print);
      return;
    }

    _ensureLines();
    _lines.add("");

    _lines.add(header);
    _lines.addAll(entries);
    _save();
  }

  void _ensureLines() {
    if (_lines == null) {
      _lines = new File(path).readAsLinesSync();
    }
  }

  void _save() {
    new File(path).writeAsStringSync(_lines.join("\n") + "\n");

    // It needs to be reparsed now since the lines have changed.
    // TODO(rnystrom): This is kind of hacky and slow, but it gets the job done.
    _statusFile = null;
    _lines = null;
  }
}
