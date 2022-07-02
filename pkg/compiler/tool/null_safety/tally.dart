// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Script to count progress of the pkg/compiler/lib/ migration

import 'dart:io';

void main(List<String> args) {
  var path = args.isEmpty ? 'pkg/compiler/lib/' : args.first;
  var dart2jsDir = Directory.fromUri(Uri.base.resolve(path));
  var entries = <FileData>[];
  for (var file in dart2jsDir.listSync(recursive: true)) {
    if (file is File && file.uri.path.endsWith('.dart')) {
      entries.add(FileData(file));
    }
  }

  var tally = Tally();
  for (var e in entries) {
    tally.totalFiles++;
    tally.totalBytes += e.sizeBytes;
    tally.totalLOC += e.sizeLOC;
    if (e.nullSafe) {
      tally.migratedFiles++;
      tally.migratedBytes += e.sizeBytes;
      tally.migratedLOC += e.sizeLOC;
    }
  }

  print(tally.formatString());
  //print(tally.csvRow());
}

/// Details about each file in the package to properly count migration progress.
class FileData {
  final Uri path;
  final int sizeBytes;
  final int sizeLOC;
  final bool nullSafe;

  FileData._(this.path, this.sizeBytes, this.sizeLOC, this.nullSafe);

  factory FileData(File file) {
    var contents = file.readAsStringSync();
    var length = contents.length;
    var sizeLOC = '\n'.allMatches(contents).length;
    var nullSafe = !contents.contains("// @dart = 2.10");
    return FileData._(file.uri, length, sizeLOC, nullSafe);
  }
}

/// Cumulative information about the status of the null safety migration.
class Tally {
  int totalFiles = 0;
  int migratedFiles = 0;
  int totalBytes = 0;
  int migratedBytes = 0;
  int totalLOC = 0;
  int migratedLOC = 0;

  /// Emit a readable table representation of the null safety progress.
  String formatString() {
    String _pad(String text, int width) {
      return (' ' * (10 - text.length)) + text;
    }

    String _row(String name, int a, int b) {
      var padA = _pad('$a', 10);
      var padB = _pad('$b', 10);
      var padC = _pad((a * 100 / b).toStringAsFixed(2), 10);
      return '${_pad(name, 8)} $padA $padB $padC%';
    }

    return '${_pad("", 10)} ${_pad("migrated", 10)} ${_pad("total", 10)} ${_pad("%", 10)}\n'
        '${_row('Files', migratedFiles, totalFiles)}\n'
        '${_row('Lines', migratedLOC, totalLOC)}\n'
        '${_row('Bytes', migratedBytes, totalBytes)}';
  }

  /// Emit a csv representation of the null safety progress, useful to track
  /// data over time.
  String csvRow() => [
        totalFiles,
        migratedFiles,
        totalBytes,
        migratedBytes,
        totalLOC,
        migratedLOC,
      ].join(',');
}
