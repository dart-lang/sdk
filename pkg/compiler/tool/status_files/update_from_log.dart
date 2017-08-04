// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Script that updates dart2js status lines automatically for tests under the
/// '$dart2js_with_kernel' configuration.
///
/// This script is hardcoded to only support this configuration and relies on
/// a convention for how the status files are structured, In particular,
/// every status file for dart2js should have 2 sections:
///
///   [ $compiler == dart2js && $dart2js_with_kernel && $host_checked ]
///
/// and:
///
///     [ $compiler == dart2js && $dart2js_with_kernel && $minified ]
library status_files.update_from_log;

import 'dart:io';

import 'record.dart';
import 'log_parser.dart';

final configurations = {
  'checked':
      r'[ $compiler == dart2js && $dart2js_with_kernel && $host_checked ]',
  'minified': r'[ $compiler == dart2js && $dart2js_with_kernel && $minified ]',
};

final statusFiles = {
  'language': 'tests/language/language_dart2js.status',
  'corelib': 'tests/corelib/corelib.status',
  'language_2': 'tests/language_2/language_2_dart2js.status',
  // TODO(sigmund,rnystrom): update when corelib_2 gets split into multiple
  // status files.
  'corelib_2': 'tests/corelib_2/corelib_2.status',
  'dart2js_extra': 'tests/compiler/dart2js_extra/dart2js_extra.status',
  'dart2js_native': 'tests/compiler/dart2js_native/dart2js_native.status',
};

main(args) {
  if (args.length < 2) {
    print('usage: udpate_from_log.dart <mode> log.txt');
    print('  where mode is one of these values: ${configurations.keys}');
    exit(1);
  }
  var mode = args[0];
  if (!configurations.containsKey(mode)) {
    print('invalid mode: $mode, expected one in ${configurations.keys}');
    exit(1);
  }

  var uri = Uri.base.resolve(args[1]);
  var file = new File.fromUri(uri);
  if (!file.existsSync()) {
    print('file not found: $file');
    exit(1);
  }

  updateLogs(mode, file.readAsStringSync());
}

/// Update all status files based on the [log] records when running the compiler
/// in [mode].
void updateLogs(String mode, String log) {
  List<Record> records = parse(log);
  records.sort();
  var last;
  var section;
  for (var record in records) {
    if (last == record) continue; // ignore duplicates
    if (section?.suite != record.suite) {
      section?.update();
      section = ConfigurationInSuiteSection.create(record.suite, mode);
    }
    section.add(record);
    last = record;
  }
  section?.update();
}

/// Represents an existing entry in the logs.
class ExistingEntry {
  final String test;
  final String status;

  ExistingEntry(this.test, this.status);

  static parse(String line) {
    var colonIndex = line.indexOf(':');
    var test = line.substring(0, colonIndex);
    var status = line.substring(colonIndex + 1).trim();
    var commentIndex = status.indexOf("#");
    if (commentIndex != -1) {
      status = status.substring(0, commentIndex);
    }
    return new ExistingEntry(test, status);
  }
}

/// Represents a section in a .status file that corresponds to a specific suite
/// and configuration.
class ConfigurationInSuiteSection {
  final String suite;
  final String _statusFile;
  final String _contents;
  final int _begin;
  final int _end;
  final List<Record> _records = [];

  ConfigurationInSuiteSection(
      this.suite, this._statusFile, this._contents, this._begin, this._end);

  /// Add a new test record, indicating that the test status should be updated.
  void add(Record record) => _records.add(record);

  /// Update the section in the file.
  ///
  /// This will reflect the new status lines as recorded in [_records].
  void update() {
    int changes = 0;
    int ignored = 0;
    var originalEntries = _contents.substring(_begin, _end).split('\n');

    // The algorithm below walks entries in the file and from the log in the
    // same order: preserving entries that didn't change, and updating entries
    // where the logs show that the test status changed.

    // Records are already sorted, but we sort the file contents in case the
    // file has been tampered with.
    originalEntries.sort();

    var newContents = new StringBuffer();
    newContents.write(_contents.substring(0, _begin));
    addFromRecord(Record record) {
      newContents.writeln('${record.test}: ${record.actual}');
    }

    int i = 0, j = 0;
    while (i < originalEntries.length && j < _records.length) {
      var existingLine = originalEntries[i];
      if (existingLine.trim().isEmpty) {
        i++;
        continue;
      }
      var existing = ExistingEntry.parse(existingLine);
      var record = _records[j];
      var compare = existing.test.compareTo(record.test);
      if (compare < 0) {
        // Existing test was unaffected, copy the status line.
        newContents.writeln(existingLine);
        i++;
      } else if (compare > 0) {
        // New entry, if it's a failure, we haven't seen this before and must
        // add it. If the status says it is passing, we ignore it. We do this
        // to support making this script idempotent if the patching has already
        // been done.
        if (!record.isPassing) {
          // New failure never seen before
          addFromRecord(record);
          changes++;
        }
        j++;
      } else if (existing.status == record.actual) {
        // This also should only happen if the patching has already been done.
        // We don't complain to make this script idempotent.
        newContents.writeln(existingLine);
        ignored++;
        i++;
        j++;
      } else {
        changes++;
        // The status changed, if it is now passing, we omit the entry entirely,
        // otherwise we use the status from the logs.
        if (!record.isPassing) {
          addFromRecord(record);
        }
        i++;
        j++;
      }
    }

    for (; i < originalEntries.length; i++) {
      newContents.writeln(originalEntries[i]);
    }

    for (; j < _records.length; j++) {
      changes++;
      addFromRecord(_records[j]);
    }

    newContents.write('\n');
    newContents.write(_contents.substring(_end));
    new File(_statusFile).writeAsStringSync('$newContents');
    print("updated '$_statusFile' with $changes changes");
    if (ignored > 0) {
      print('  $ignored changes were already applied in the status file.');
    }
  }

  static ConfigurationInSuiteSection create(String suite, String mode) {
    var statusFile = statusFiles[suite];
    var contents = new File(statusFile).readAsStringSync();
    var condition = configurations[mode];
    int sectionDeclaration = contents.indexOf(condition);
    if (sectionDeclaration == -1) {
      print('error: unable to find condition $condition in $statusFile');
      exit(1);
    }
    int begin = contents.indexOf('\n', sectionDeclaration) + 1;
    assert(begin != 0);
    int end = contents.indexOf('\n[', begin + 1);
    end = end == -1 ? contents.length : end + 1;
    return new ConfigurationInSuiteSection(
        suite, statusFile, contents, begin, end);
  }
}
