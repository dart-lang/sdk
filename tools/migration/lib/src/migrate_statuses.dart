// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import 'editable_status_file.dart';
import 'fork.dart';
import 'io.dart';
import 'test_directories.dart';

/// Migrates the status file entries that match [files].
void migrateStatusEntries(List<Fork> files) {
  var entriesToMove = new EntrySet();

  _collectEntries(files, entriesToMove, isOne: true);
  _collectEntries(files, entriesToMove, isOne: false);

  for (var statusFile in entriesToMove.statusFiles) {
    var sections = entriesToMove.sections(statusFile);
    _addEntries(statusFile, sections);
  }

  // TODO(rnystrom): Should this log any output?
}

/// Tracks a set of entries to add to a set of Dart 2.0 status files.
class EntrySet {
  /// Keys are the names of the Dart 2.0 status file that will receive the
  /// entries. The value for each key is a map of section headers to the list
  /// of entries to add under that section.
  final Map<String, Map<String, List<String>>> _files = {};

  Iterable<String> get statusFiles => _files.keys;

  void add(String fromDir, String header, String entry) {
    var toDir = toTwoDirectory(fromDir);
    var sections = _files.putIfAbsent(p.join(toDir, "$toDir.status"), () => {});
    var entries = sections.putIfAbsent(header, () => []);
    entries.add(entry);
  }

  Map<String, List<String>> sections(String file) => _files[file];
}

/// Removes entries from the 1.0 and strong status files that correspond to
/// the list of [files] being migrated.
///
/// Adds moved entries to [entriesToMove].
void _collectEntries(List<Fork> files, EntrySet entriesToMove, {bool isOne}) {
  // Map the files to the way they will appear in the status file.
  var filePaths = files
      .map((fork) => p.withoutExtension(isOne ? fork.onePath : fork.strongPath))
      .toList();

  for (var fromDir in isOne ? oneRootDirs : strongRootDirs) {
    for (var path in listFiles(fromDir, extension: ".status")) {
      var editable = new EditableStatusFile(path);

      var deleteLines = <int>[];
      for (var section in editable.statusFile.sections) {
        // TODO(rnystrom): For now, we don't support entries in the initial
        // implicit section at the top of the file. Do we need to?
        if (section.condition == null) continue;

        for (var entry in section.entries) {
          var entryPath = p.join(fromDir, entry.path);

          for (var filePath in filePaths) {
            // We only support entries that precisely match the file being
            // migrated, or a multitest within that. In both cases, the entry
            // path will begin with the full path of the file. We don't migrate
            // directory or glob patterns because those may also match other
            // files that have not been migrated yet.
            // TODO(rnystrom): It would be good to detect when a glob matches
            // a migrated file and let the user know that they may need to
            // manually handle it.
            if (!entryPath.startsWith(filePath)) continue;

            // Remove it from this status file.
            deleteLines.add(entry.lineNumber - 1);

            // And add it to the 2.0 one.
            entriesToMove.add(fromDir, editable.lineAt(section.lineNumber),
                editable.lineAt(entry.lineNumber));
          }
        }
      }

      // TODO(rnystrom): If all of the entries are deleted from a section, it
      // would be nice to delete the section header too.
      editable.delete(deleteLines);
    }
  }
}

/// Adds all of [entries] to the status file at [path].
///
/// If the status file already has a section that matches a header in [entries],
/// then adds those entries to the end of that section. Otherwise, appends a
/// new section to the end of the file.
void _addEntries(String path, Map<String, List<String>> entries) {
  var editable = new EditableStatusFile(p.join(testRoot, path));

  for (var header in entries.keys) {
    var found = false;

    // Look for an existing section with the same header to add it to.
    for (var section in editable.statusFile.sections) {
      if (header == editable.lineAt(section.lineNumber)) {
        var line = section.lineNumber;
        // Add after existing entries, if there are any.
        if (section.entries.isNotEmpty) {
          line = section.entries.last.lineNumber;
        }

        editable.insert(line, entries[header]);
        found = true;
        break;
      }
    }

    if (!found) {
      // This section doesn't exist in the status file, so add it.
      editable.append(header, entries[header]);
    }
  }
}
