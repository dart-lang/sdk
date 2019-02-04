// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Script that updates dart2js status lines automatically for tests under the
/// '$fasta' configuration.
///
/// This script is hardcoded to only support this configuration and relies on
/// a convention for how the status files are structured, In particular,
/// every status file for dart2js should have 3 sections:
///
///     [ $compiler == dart2js && $fasta && $host_checked ]
///
/// and:
///
///     [ $compiler == dart2js && $fasta && $minified ]
///
/// and:
///
///     [ $compiler == dart2js && $fasta && $fast_startup ]
///
/// and:
///
///     [ $compiler == dart2js && $checked && $fasta ]
library compiler.status_files.update_from_log;

import 'dart:io';

import 'record.dart';
import 'log_parser.dart';

final dart2jsConfigurations = {
  'host-checked': r'[ $compiler == dart2js && $fasta && $host_checked ]',
  'minified': r'[ $compiler == dart2js && $fasta && $minified ]',
  'host-checked-strong':
      r'[ $compiler == dart2js && $fasta && $host_checked && $strong ]',
  'minified-strong':
      r'[ $compiler == dart2js && $fasta && $minified && $strong ]',
  'fast-startup': r'[ $compiler == dart2js && $fast_startup && $fasta ]',
  'fast-startup-strong':
      r'[ $compiler == dart2js && $fast_startup && $fasta && $strong ]',
  'checked-mode': r'[ $compiler == dart2js && $checked && $fasta ]',
  'checked-mode-strong':
      r'[ $compiler == dart2js && $checked && $fasta && $strong ]',
};

final dart2jsStatusFiles = {
  'language_2': 'tests/language_2/language_2_dart2js.status',
  // TODO(sigmund,rnystrom): update when corelib_2 gets split into multiple
  // status files.
  'corelib_2': 'tests/corelib_2/corelib_2.status',
  'dart2js_extra': 'tests/compiler/dart2js_extra/dart2js_extra.status',
  'dart2js_native': 'tests/compiler/dart2js_native/dart2js_native.status',
};

main(args) {
  mainInternal(args, dart2jsConfigurations, dart2jsStatusFiles);
}

/// Note: this is called above and also from
/// pkg/front_end/tool/status_files/update_from_log.dart
mainInternal(List<String> args, Map<String, String> configurations,
    Map<String, String> statusFiles) {
  if (args.length < 2) {
    print('usage: update_from_log.dart <mode> log.txt [message-in-quotes]');
    print('  where mode is one of these values: ${configurations.keys}');
    exit(1);
  }
  var mode = args[0];
  if (!configurations.containsKey(mode)) {
    print('invalid mode: $mode, expected one in ${configurations.keys}');
    exit(1);
  }

  var uri =
      Uri.base.resolveUri(new Uri.file(args[1], windows: Platform.isWindows));
  var file = new File.fromUri(uri);
  if (!file.existsSync()) {
    print('file not found: $file');
    exit(1);
  }

  var globalReason = args.length > 2 ? args[2] : null;
  updateLogs(
      mode, file.readAsStringSync(), configurations, statusFiles, globalReason);
}

/// Update all status files based on the [log] records when running the compiler
/// in [mode]. If provided [globalReason] is added as a comment to new test
/// failures. If not, an automated reason might be extracted from the test
/// failure message.
void updateLogs(String mode, String log, Map<String, String> configurations,
    Map<String, String> statusFiles, String globalReason) {
  List<Record> records = parse(log);
  records.sort();
  var last;
  ConfigurationInSuiteSection section;
  for (var record in records) {
    if (last == record) continue; // ignore duplicates
    if (section?.suite != record.suite) {
      section?.update(globalReason);
      var statusFile = statusFiles[record.suite];
      if (statusFile == null) {
        print("No status file for suite '${record.suite}'.");
        continue;
      }
      var condition = configurations[mode];
      section = ConfigurationInSuiteSection.create(
          record.suite, mode, statusFile, condition);
    }
    section.add(record);
    last = record;
  }
  section?.update(globalReason);
}

/// Represents an existing entry in the logs.
class ExistingEntry {
  final String test;
  final String status;
  final bool hasComment;

  ExistingEntry(this.test, this.status, this.hasComment);

  static parse(String line) {
    var colonIndex = line.indexOf(':');
    var test = line.substring(0, colonIndex);
    var status = line.substring(colonIndex + 1).trim();
    var commentIndex = status.indexOf("#");
    if (commentIndex != -1) {
      status = status.substring(0, commentIndex);
    }
    return new ExistingEntry(test, status, commentIndex != -1);
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
  void update(String providedReason) {
    int changes = 0;
    int ignored = 0;
    var originalEntries = _contents.substring(_begin, _end).split('\n');

    // The algorithm below walks entries in the file and from the log in the
    // same order: preserving entries that didn't change, and updating entries
    // where the logs show that the test status changed.

    // Sort the file contents in case the file has been tampered with.
    originalEntries.sort();

    /// Re-sort records by name (they came sorted by suite and status first, so
    /// it may be wrong for the merging below).
    _records.sort((a, b) => a.test.compareTo(b.test));

    var newContents = new StringBuffer();
    newContents.write(_contents.substring(0, _begin));
    addFromRecord(Record record) {
      var reason = providedReason ?? record.reason;
      var comment = reason != null && reason.isNotEmpty ? ' # ${reason}' : '';
      newContents.writeln('${record.test}: ${record.actual}$comment');
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
        if (!existing.hasComment && record.reason != null) {
          addFromRecord(record);
          changes++;
        } else {
          // This also should only happen if the patching has already been done.
          // We don't complain to make this script idempotent.
          newContents.writeln(existingLine);
        }
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

  static ConfigurationInSuiteSection create(
      String suite, String mode, String statusFile, String condition) {
    var contents = new File(statusFile).readAsStringSync();
    int sectionDeclaration = contents.indexOf(condition);
    if (sectionDeclaration == -1) {
      print('error: unable to find condition $condition in $statusFile');
      exit(1);
    }
    int begin = contents.indexOf('\n', sectionDeclaration) + 1;
    assert(begin != 0);
    int newlinePos = contents.indexOf('\n', begin + 1);
    int end = newlinePos;
    while (true) {
      if (newlinePos == -1) break;
      if (newlinePos + 1 < contents.length) {
        if (contents[newlinePos + 1] == '[') {
          // We've found the end of the section
          break;
        } else if (contents[newlinePos + 1] == '#') {
          // We've found a commented out line.  This line might belong to the
          // next section.
          newlinePos = contents.indexOf('\n', newlinePos + 1);
          continue;
        }
      }
      // We've found an ordinary line.  It's part of this section, so update
      // end.
      newlinePos = contents.indexOf('\n', newlinePos + 1);
      end = newlinePos;
    }
    end = end == -1 ? contents.length : end + 1;
    return new ConfigurationInSuiteSection(
        suite, statusFile, contents, begin, end);
  }
}
