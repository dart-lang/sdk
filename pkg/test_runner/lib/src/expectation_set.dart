// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:status_file/expectation.dart';
import 'package:status_file/status_file.dart';

import 'configuration.dart';
import 'environment.dart';

/// Tracks the [Expectation]s associated with a set of file paths.
///
/// For any given file path, returns the expected test results for that file.
/// A set can be loaded from a collection of status files. A file path may
/// exist in multiple files (or even multiple sections within the file). When
/// that happens, all of the expectations of every entry are unioned together
/// and the test is considered to pass if the outcome is any of those
/// expectations.
class ExpectationSet {
  static final _passSet = {Expectation.pass};

  /// A cache of path component glob strings (like "b*r") that we've previously
  /// converted to regexes. This ensures we collapse multiple globs from the
  /// same string to the same map key in [_PathNode.regExpChildren].
  final Map<String, RegExp> _globCache = {};

  /// The root of the expectation tree.
  final _PathNode _tree = _PathNode();

  /// Reads the expectations defined by the status files at [statusFilePaths]
  /// when in [configuration].
  ExpectationSet.read(
      List<String> statusFilePaths, TestConfiguration configuration) {
    try {
      var environment = ConfigurationEnvironment(configuration);
      for (var path in statusFilePaths) {
        var file = StatusFile.read(path);
        file.validate(environment);
        for (var section in file.sections) {
          if (section.isEnabled(environment)) {
            for (var entry in section.entries) {
              addEntry(entry);
            }
          }
        }
      }
    } on SyntaxError catch (error) {
      stderr.writeln(error.toString());
      exit(1);
    }
  }

  /// Add [entry] to the set of expectations.
  void addEntry(StatusEntry entry) {
    var tree = _tree;
    for (var part in entry.path.split('/')) {
      if (part.contains("*")) {
        var regExp = _globCache.putIfAbsent(part, () {
          return RegExp("^" + part.replaceAll("*", ".*") + r"$");
        });
        tree = tree.regExpChildren.putIfAbsent(regExp, () => _PathNode());
      } else {
        tree = tree.stringChildren.putIfAbsent(part, () => _PathNode());
      }
    }

    tree.expectations.addAll(entry.expectations);
  }

  /// Get the expectations for the test at [path].
  ///
  /// For every (key, expectation) pair, matches the key with the file name.
  /// Returns the union of the expectations for all the keys that match.
  ///
  /// Normal matching splits the key and the filename into path components and
  /// checks that the anchored regular expression "^$keyComponent\$" matches
  /// the corresponding filename component.
  Set<Expectation> expectations(String path) {
    var result = <Expectation>{};
    _tree.walk(path.split('/'), 0, result);

    // If no status files modified the expectation, default to the test passing.
    if (result.isEmpty) return _passSet;

    return result;
  }
}

/// A single file system path component in the tree of expectations.
///
/// Given a list of status file entry paths (which may contain globs at various
/// parts), we parse it into a tree of nodes. Then, later, when looking up the
/// status for a single test, this lets us quickly consider only the status
/// file entries that relate to that test.
class _PathNode {
  /// The non-glob child directory and file paths within this directory.
  final Map<String, _PathNode> stringChildren = {};

  /// The glob child directory and file paths within this directory.
  final Map<RegExp, _PathNode> regExpChildren = {};

  /// The test expectatations that any test within this directory should
  /// include.
  final Set<Expectation> expectations = {};

  /// Walks the list of path [parts], starting at [index] adding any
  /// expectations to [result] from this node and any of its matching children.
  ///
  /// We need to include all matching children because multiple children may
  /// match a single test, as in:
  ///
  ///     foo/bar/baz: Timeout
  ///     foo/b*r/baz: Skip
  ///     foo/*ar/baz: SkipByDesign
  ///
  /// Assuming this node is for "foo" and we are walking ["bar", "baz"], all
  /// three of the above should match and the resulting expectation set should
  /// include all three.
  ///
  /// Also if a status file entry is a prefix of the test's path, that matches
  /// too:
  ///
  ///     foo/bar: Skip
  ///
  /// If the test path is "foo/baz/baz", the above entry will match it.
  void walk(List<String> parts, int index, Set<Expectation> result) {
    // We've reached this node itself, so add its expectations.
    result.addAll(expectations);

    // If this is a leaf node, stop traversing.
    if (index >= parts.length) return;

    var part = parts[index];

    // Look for a non-glob child directory.
    if (stringChildren.containsKey(part)) {
      stringChildren[part].walk(parts, index + 1, result);
    }

    // Look for any matching glob directories.
    for (var regExp in regExpChildren.keys) {
      if (regExp.hasMatch(part)) {
        regExpChildren[regExp].walk(parts, index + 1, result);
      }
    }
  }
}
