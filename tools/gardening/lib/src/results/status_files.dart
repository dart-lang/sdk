// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:gardening/src/results/configuration_environment.dart';
import 'package:gardening/src/util.dart';
import 'package:status_file/status_file.dart';

class StatusFiles {
  final List<StatusFile> _statusFiles;
  List<StatusSectionEntry> _entries;
  Map<StatusEntry, List<RegExp>> _keyToRegExps = {};

  /// Constructs a [StatusFiles] from a list of status file paths.
  static StatusFiles read(Iterable<String> files) {
    return new StatusFiles(files.map((file) {
      return new StatusFile.read(file);
    }).toList());
  }

  StatusFiles(this._statusFiles) {
    _entries = _statusFiles
        .expand((file) =>
            file.sections.expand((section) => section.entries.map((entry) {
                  _keyToRegExps[entry] = _processForMatching(entry.path);
                  return new StatusSectionEntry(file, section, entry);
                })))
        .toList();
  }

  /// Gets all section entries with test-expectations for a configuration
  /// environment.
  List<StatusSectionEntry> sectionsWithTestForConfiguration(
      ConfigurationEnvironment environment, String testPath) {
    var parts = testPath.split('/');
    return _entries.where((entry) {
      if (!entry.section.isEnabled(environment)) return false;
      List<RegExp> pathRegExps = _keyToRegExps[entry.entry];
      return pathRegExps.length <= parts.length &&
          zipWith(pathRegExps, parts, (regExp, part) {
            return regExp.hasMatch(part);
          }).every((hasMatch) => hasMatch);
    }).toList();
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
