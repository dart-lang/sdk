// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:gardening/src/results/configuration_environment.dart';
import 'package:status_file/canonical_status_file.dart';

class StatusFiles {
  Map<String, List<StatusSectionEntry>> _exactEntries = {};
  Map<StatusSectionEntry, List<RegExp>> _wildcardEntries = {};
  List<StatusSectionWithFile> _sections = [];
  final List<StatusFile> statusFiles;

  /// Constructs a [StatusFiles] from a list of status file paths.
  static StatusFiles read(Iterable<String> files) {
    var distinctFiles = new Set.from(files).toList();
    return new StatusFiles(distinctFiles.map((file) {
      return new StatusFile.read(file);
    }).toList());
  }

  StatusFiles(this.statusFiles) {
    for (var file in statusFiles) {
      for (var section in file.sections) {
        _sections.add(new StatusSectionWithFile(file, section));
        for (StatusEntry entry
            in section.entries.where((entry) => entry is StatusEntry)) {
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
  List<StatusSectionWithFile> sectionsForConfiguration(
      ConfigurationEnvironment environment) {
    return _sections.where((s) => s.section.isEnabled(environment)).toList();
  }

  /// Gets all section entries with test-expectations for a configuration
  /// environment.
  List<StatusSectionEntry> sectionsWithTestForConfiguration(
      ConfigurationEnvironment environment, String testPath) {
    return sectionsWithTest(testPath)
        .where((entry) => entry.section.isEnabled(environment))
        .toList();
  }

  /// Gets all section entries with test-expectations for a configuration
  /// environment.
  List<StatusSectionEntry> sectionsWithTest(String testPath) {
    List<StatusSectionEntry> matchingEntries = <StatusSectionEntry>[];
    if (_exactEntries.containsKey(testPath)) {
      matchingEntries.addAll(_exactEntries[testPath]);
    }
    // Test if it is a multi test by matching finding the name of the test
    // (either by the test name ending with _test/ or _t<nr>/ and cutting out
    // the remaining, as long as it does not contain the word _test
    RegExp isMultiTestMatcher = new RegExp(r"^((.*)_(test|t\d+))\/(.+)$");
    Match isMultiTestMatch = isMultiTestMatcher.firstMatch(testPath);
    if (isMultiTestMatch != null) {
      String testFile = isMultiTestMatch.group(1);
      if (_exactEntries.containsKey(testFile)) {
        matchingEntries.addAll(_exactEntries[testFile]);
      }
      var multiTestParts = isMultiTestMatch.group(4).split('/');
      for (var part in multiTestParts) {
        testFile = "$testFile/$part";
        if (_exactEntries.containsKey(testFile)) {
          matchingEntries.addAll(_exactEntries[testFile]);
        }
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

    return matchingEntries;
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

/// [StatusSectionWithFile] holds information about a section and the status
/// file it belongs to.
class StatusSectionWithFile {
  final StatusFile statusFile;
  final StatusSection section;
  StatusSectionWithFile(this.statusFile, this.section);
}
