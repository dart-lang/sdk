// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:gardening/src/results/configuration_environment.dart';
import 'package:gardening/src/util.dart';
import 'package:status_file/status_file.dart';

class StatusFiles {
  Map<String, List<StatusSectionEntry>> _exactEntries = {};
  Map<StatusSectionEntry, List<RegExp>> _wildcardEntries = {};

  /// Constructs a [StatusFiles] from a list of status file paths.
  static StatusFiles read(Iterable<String> files) {
    return new StatusFiles(files.map((file) {
      return new StatusFile.read(file);
    }).toList());
  }

  StatusFiles(List<StatusFile> statusFiles) {
    for (var file in statusFiles) {
      for (var section in file.sections) {
        for (var entry in section.entries) {
          var sectionEntry = new StatusSectionEntry(file, section, entry);
          if (entry.path.contains("*")) {
            _wildcardEntries[sectionEntry] = _processForMatching(entry.path);
          } else {
            _exactEntries.putIfAbsent(entry.path, () => []).add(sectionEntry);
          }
        }
      }
    }
  }

  /// Gets all section entries with test-expectations for a configuration
  /// environment.
  List<StatusSectionEntry> sectionsWithTestForConfiguration(
      ConfigurationEnvironment environment, String testPath) {
    List<StatusSectionEntry> matchingEntries = <StatusSectionEntry>[];
    if (_exactEntries.containsKey(testPath)) {
      matchingEntries.addAll(_exactEntries[testPath]);
    }
    // Test if it is a multi test.
    RegExp isMultiTestMatcher = new RegExp(r"^((.*)_(test|t\d+))\/[^\/]+$");
    Match isMultiTestMatch = isMultiTestMatcher.firstMatch(testPath);
    if (isMultiTestMatch != null) {
      String testFile = isMultiTestMatch.group(1);
      if (_exactEntries.containsKey(testFile)) {
        matchingEntries.addAll(_exactEntries[testFile]);
      }
    }

    var parts = testPath.split('/');
    _wildcardEntries.forEach((entry, regExps) {
      if (regExps.length > parts.length) return;
      for (var i = 0; i < regExps.length; i++) {
        if (!regExps[i].hasMatch(parts[i])) return;
      }
      matchingEntries.add(entry);
    });

    return matchingEntries
        .where((entry) => entry.section.isEnabled(environment))
        .toList();
  }

  /// Processes the expectations for matching against filenames. Generates
  /// lists of regular expressions once and for all for a key.
  List<RegExp> _processForMatching(String key) {
    return key
        .split('/')
        .map((part) => new RegExp("^${part}\$".replaceAll('*', '.*')))
        .toList();
  }
}

/// [StatusSectionEntry] is a result from looking up a test, and holds
/// information about the status file, the section and the specific entry.
class StatusSectionEntry {
  final StatusFile statusFile;
  final StatusSection section;
  final StatusEntry entry;
  StatusSectionEntry(this.statusFile, this.section, this.entry);
}
