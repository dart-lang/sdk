// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import 'editable_status_file.dart';
import 'fork.dart';
import 'io.dart';
import 'log.dart';
import 'test_directories.dart';

/// Migrates the status file entries that match [files].
void migrateStatusEntries(List<Fork> files, Map<String, List<String>> todos) {
  var entriesToMove = new EntrySet();

  _collectEntries(files, entriesToMove, isOne: true);
  _collectEntries(files, entriesToMove, isOne: false);

  for (var statusFile in entriesToMove.statusFiles) {
    var sections = entriesToMove.sections(statusFile);
    _addEntries(statusFile, sections);
  }

  // If any entries need manual splitting, let the user know.
  for (var statusFile in entriesToMove._todoHeaders.keys) {
    var headers = entriesToMove._todoHeaders[statusFile];
    var splits = headers.map((header) {
      var files = filesForHeader(header).map((file) => bold(file)).join(", ");
      return "Manually split status file section across $files status files:\n"
          "    $header";
    }).toList();

    if (splits.isNotEmpty) todos[statusFile] = splits;
  }
}

/// Given the header for a status file section, looks at the condition
/// expression to determine which status files it should go in.
Set<String> filesForHeader(String header) {
  // Figure out which status file it goes into.
  var result = new Set<String>();

  // The various compilers are roughly separate products.
  const compilers = const {
    r"$compiler == dart2analyzer": "analyzer",
    r"$compiler == dart2js": "dart2js",
    r"$compiler == dartdevc": "dartdevc",
    // This deliberately matches both dartk and dartkp.
    r"$compiler == dartk": "kernel",
    r"$compiler == precompiler": "precompiled"
  };

  // TODO(rnystrom): This is obviously very sensitive to the formatting of
  // the expression. Hacky, but hopefully good enough for now.
  compilers.forEach((compiler, file) {
    if (header.contains(compiler)) result.add(file);
  });

  // If we couldn't figure out where to put it based on the compiler, look at
  // the runtime.
  if (result.isEmpty) {
    const runtimes = const {
      r"$runtime == vm": "vm",
      r"$runtime == flutter": "flutter",
      r"$runtime == dart_precompiled": "precompiled",
    };

    runtimes.forEach((runtime, file) {
      if (header.contains(runtime)) result.add(file);
    });
  }

  return result;
}

/// Tracks a set of entries to add to a set of Dart 2.0 status files.
class EntrySet {
  /// Keys are the names of the Dart 2.0 status file that will receive the
  /// entries. The value for each key is a map of section headers to the list
  /// of entries to add under that section.
  final Map<String, Map<String, List<String>>> _files = {};

  final _todoHeaders = <String, Set<String>>{};

  Iterable<String> get statusFiles => _files.keys;

  /// Attempts to add the [entry] under [header] in a status file in [fromDir]
  /// to this EntrySet.
  ///
  /// Returns true if successful or false if the header's condition doesn't fit
  /// into a single status file and needs to be manually split by the user.
  bool add(String fromFile, String fromDir, String header, String entry) {
    var toDir = toTwoDirectory(fromDir);

    // Figure out which status file it goes into.
    var possibleFiles = filesForHeader(header);
    var destination = "$toDir.status";

    if (possibleFiles.length > 1) {
      // The condition matches multiple files, so the user is going to have to
      // manually split it up into multiple sections first.
      // TODO(rnystrom): Would be good to automate this, though it requires
      // being able to work with condition expressions directly.
      var statusRelative = p.relative(fromFile, from: testRoot);
      _todoHeaders.putIfAbsent(statusRelative, () => new Set()).add(header);
      return false;
    }

    // The main "_strong.status" files skip lots of tests that are or were not
    // strong mode clean. We don't want to skip those tests in 2.0 -- we want
    // to fix them. If we're in that header, do remove the entry from the old
    // file, but don't add it to the new one.
    if (header == "[ \$strong ]") return true;

    // If the condition places it directly into one file, put it there.
    if (possibleFiles.length == 1) {
      destination = "${toDir}_${possibleFiles.single}.status";
    }

    var sections = _files.putIfAbsent(p.join(toDir, destination), () => {});

    var entries = sections.putIfAbsent(header, () => []);
    entries.add(entry);
    return true;
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

            // Add it to the 2.0 one.
            if (entriesToMove.add(
                path,
                fromDir,
                editable.lineAt(section.lineNumber),
                editable.lineAt(entry.lineNumber))) {
              // Remove it from the original status file.
              deleteLines.add(entry.lineNumber - 1);
            }
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
